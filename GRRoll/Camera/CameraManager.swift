import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal
import MetalKit
import UIKit

// MARK: - 相机管理（实时套 LUT 取景 + 拍照）
/// 打开即拍，所见即所得：视频帧实时经过 GRLookFilter 渲染到 Metal 视图。
final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var ciContext = CIContext()
    private let filter = GRLookFilter()

    private let videoQueue = DispatchQueue(label: "grroll.camera.video")
    private let lock = NSLock()
    private var latestFrame: CIImage?

    /// 注入的 Metal 预览视图
    private weak var metalView: MTKView?

    // 当前影调 / 参数 / 画幅
    @Published var currentLook: FilmLook = .default
    @Published var params: LookParameters = .default
    @Published var ratio: CaptureRatio = .r3x2

    @Published var isSessionRunning = false

    // 拍照回调
    private var photoCompletion: ((UIImage?) -> Void)?
    private var lastCaptureSettings = AVCapturePhotoSettings()

    // MARK: - 绑定 Metal 视图
    func attach(metalView: MTKView) {
        self.metalView = metalView
        if metalView.device == nil { metalView.device = MTLCreateSystemDefaultDevice() }
        // 用预览视图的 Metal 设备创建 CIContext，保证可直接渲染到 drawable 纹理
        if let device = metalView.device { ciContext = CIContext(mtlDevice: device) }
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true
        metalView.framebufferOnly = false
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.delegate = self
    }

    // MARK: - 会话配置
    func configure() {
        // 已配置过（已有输入）则跳过，避免重复添加
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        // 方向：竖拍固定，取帧与拍照统一在代码里旋转为竖构图（不再依赖连接旋转，避免双重旋转）
        session.commitConfiguration()
    }

    func start() {
        configure()
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async { self?.isSessionRunning = self?.session.isRunning ?? false }
        }
    }

    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
        isSessionRunning = false
    }

    // MARK: - 拍照（套当前 LUT，按画幅裁剪）
    func takePhoto(completion: @escaping (UIImage?) -> Void) {
        guard session.isRunning else { completion(nil); return }
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        lastCaptureSettings = settings
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// 把一张全分辨率图按当前画幅居中裁剪（保持原图朝向：竖拍得竖构图）
    private func cropToRatio(_ image: CIImage, ratio: CGFloat) -> CIImage {
        let w = image.extent.width
        let h = image.extent.height
        let landscape = w >= h
        let r = landscape ? ratio : 1.0 / ratio
        let current = w / h
        var crop: CGRect = image.extent
        if current > r {
            let newW = h * r
            crop = CGRect(x: (w - newW)/2, y: 0, width: newW, height: h)
        } else {
            let newH = w / r
            crop = CGRect(x: 0, y: (h - newH)/2, width: w, height: newH)
        }
        return image.cropped(to: crop)
    }
}

// MARK: - 视频帧：实时套 LUT
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        let filtered = filter.apply(ci, look: currentLook, params: params)
        lock.lock(); latestFrame = filtered; lock.unlock()
        DispatchQueue.main.async { self.metalView?.setNeedsDisplay() }
    }
}

// MARK: - 拍照结果
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let completion = photoCompletion
        photoCompletion = nil

        guard error == nil else {
            DispatchQueue.main.async { completion?(nil) }; return
        }
        var ci: CIImage?
        if let pb = photo.pixelBuffer {
            ci = CIImage(cvPixelBuffer: pb).oriented(.right)
        } else if let cg = photo.cgImageRepresentation() {
            ci = CIImage(cgImage: cg).oriented(.right)
        }
        guard let base = ci else {
            DispatchQueue.main.async { completion?(nil) }; return
        }
        let graded = filter.apply(base, look: currentLook, params: params)
        let cropped = cropToRatio(graded, ratio: ratio.value)
        guard let cg = ciContext.createCGImage(cropped, from: cropped.extent) else {
            DispatchQueue.main.async { completion?(nil) }; return
        }
        let image = UIImage(cgImage: cg, scale: 1.0, orientation: .up)
        DispatchQueue.main.async { completion?(image) }
    }
}

// MARK: - Metal 渲染
extension CameraManager: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else { return }
        lock.lock(); let frame = latestFrame; lock.unlock()
        guard let image = frame else { return }
        let bounds = CGRect(x: 0, y: 0, width: drawable.texture.width, height: drawable.texture.height)
        let fitted = image.resizedToFit(bounds)
        let cs = CGColorSpaceCreateDeviceRGB()
        ciContext.render(fitted, to: drawable.texture, commandBuffer: nil,
                         bounds: bounds, colorSpace: cs)
    }
}

// MARK: - CIImage 辅助
extension CIImage {
    /// 等比缩放并居中到目标矩形（contain）
    func resizedToFit(_ target: CGRect) -> CIImage {
        let scale = min(target.width / extent.width, target.height / extent.height)
        let resized = transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let dx = target.midX - resized.extent.midX
        let dy = target.midY - resized.extent.midY
        return resized.transformed(by: CGAffineTransform(translationX: dx, y: dy))
    }
}
