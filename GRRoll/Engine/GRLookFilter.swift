import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - 理光影调渲染引擎
/// 用 Core Image 滤镜链实时复刻理光 GR 系列 LUT，并支持逐参数微调。
/// 全部本地运算，不上传任何图片。
final class GRLookFilter {

    let context: CIContext

    init(context: CIContext = CIContext(options: [.workingColorSpace: NSNull()])) {
        self.context = context
    }

    // MARK: 主入口
    /// 对一张图套用指定 LUT 与用户参数
    func apply(_ input: CIImage, look: FilmLook, params: LookParameters) -> CIImage {
        var image = input

        // 1) 黑白先去色
        if look.mono {
            let mono = CIFilter.colorControls()
            mono.inputImage = image
            mono.saturation = 0
            image = mono.outputImage ?? image
        }

        // 2) 颜色控制：对比 / 饱和 / 亮度（叠加基础调与用户倍率）
        let controls = CIFilter.colorControls()
        controls.inputImage = image
        controls.contrast   = Float(clamp(look.baseContrast * params.contrast, 0.2, 2.5))
        controls.saturation = Float(clamp(look.baseSaturation * params.saturation, 0, 2))
        controls.brightness = Float(clamp(look.baseBrightness + params.brightness, -0.5, 0.5))
        image = controls.outputImage ?? image

        // 3) 色温 / 色偏：GR 蓝（冷阴影）+ 暖色偏移
        let temp = CIFilter.temperatureAndTint()
        temp.inputImage = image
        temp.neutral = CIVector(x: 6500, y: 0)
        // target 越低越冷（偏蓝）；warmShift>0 偏黄，<0 偏绿
        let coolK = 6500 - look.coolAmount * 1400
        let tintY = look.tintAmount * 100 + look.warmShift * 120
        temp.targetNeutral = CIVector(x: coolK, y: tintY)
        image = temp.outputImage ?? image

        // 4) 褪色 / 胶片灰雾：抬起黑位 + 整体降对比（理光负片/怀旧感）
        if params.fade > 0 {
            image = applyFade(image, amount: params.fade)
        }

        // 5) 漏光：边缘暖光晕（屏幕混合）
        if params.lightLeak > 0 {
            image = applyLightLeak(image, amount: params.lightLeak, hue: look.leakHue)
        }

        // 6) 锐度（理光机内锐化）
        if params.sharpness > 0 {
            let sharp = CIFilter.unsharpMask()
            sharp.inputImage = image
            sharp.radius = Float(params.sharpness * 2.2)
            sharp.intensity = Float(params.sharpness * 0.8)
            image = sharp.outputImage ?? image
        }

        // 7) 暗角
        if params.vignette > 0 {
            let vig = CIFilter.vignette()
            vig.inputImage = image
            vig.intensity = Float(params.vignette * 1.4)
            vig.radius = 1.1
            image = vig.outputImage ?? image
        }

        // 8) 颗粒（理光细腻胶片颗粒）
        if params.grain > 0 {
            image = applyGrain(image, intensity: params.grain, size: params.grainSize)
        }

        return image
    }

    // MARK: - 子效果
    /// 褪色：用色彩矩阵抬起黑位，模拟胶片灰雾
    private func applyFade(_ image: CIImage, amount: Double) -> CIImage {
        let m = CIFilter.colorMatrix()
        m.inputImage = image
        let lift = Float(amount * 0.18)
        // 把 0 黑位抬到 lift，并轻微压缩高光
        m.rVector = CIVector(x: 1 - lift*0.3, y: 0, z: 0, w: 0)
        m.gVector = CIVector(x: 0, y: 1 - lift*0.3, z: 0, w: 0)
        m.bVector = CIVector(x: 0, y: 0, z: 1 - lift*0.3, w: 0)
        m.biasVector = CIVector(x: lift, y: lift, z: lift, w: 0)
        return m.outputImage ?? image
    }

    /// 漏光：一侧暖色径向光晕，屏幕混合
    private func applyLightLeak(_ image: CIImage, amount: Double, hue: Double) -> CIImage {
        let extent = image.extent
        let center = CGPoint(x: extent.width * 1.15, y: extent.height * 0.15) // 右上角漏光
        let radius = Double(max(extent.width, extent.height)) * 0.9
        let leak = CIFilter.radialGradient()
        leak.center = center
        leak.radius0 = 0
        leak.radius1 = Float(radius)
        // 用色相构造暖色
        let uiColor = UIColor(hue: CGFloat(hue), saturation: 0.6, brightness: 0.9, alpha: CGFloat(amount * 0.5))
        let color = CIColor(color: uiColor)
        leak.color0 = color
        leak.color1 = CIColor(red: 0, green: 0, blue: 0, alpha: 0)
        guard let glow = leak.outputImage?.cropped(to: extent) else { return image }
        let blend = CIFilter.screenBlendMode()
        blend.inputImage = glow
        blend.backgroundImage = image
        return blend.outputImage ?? image
    }

    /// 颗粒：随机噪声 → 缩放控制颗粒大小 → 叠加混合
    private func applyGrain(_ image: CIImage, intensity: Double, size: Double) -> CIImage {
        let extent = image.extent
        // 噪声生成器为无限平面，缩放变换 <1 即可获得更粗颗粒
        let scale = 1.0 / max(size, 0.3)
        let noise = CIFilter.randomGenerator().outputImage?
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .cropped(to: extent)
        guard let n = noise else { return image }

        // 把噪声压到灰附近（振幅 = intensity），中心 0.5
        let amp = Float(intensity * 0.22)
        let matrix = CIFilter.colorMatrix()
        matrix.inputImage = n
        matrix.rVector = CIVector(x: 2*amp, y: 0, z: 0, w: 0)
        matrix.gVector = CIVector(x: 0, y: 2*amp, z: 0, w: 0)
        matrix.bVector = CIVector(x: 0, y: 0, z: 2*amp, w: 0)
        matrix.biasVector = CIVector(x: 0.5 - amp, y: 0.5 - amp, z: 0.5 - amp, w: 0)
        guard let gray = matrix.outputImage else { return image }

        let overlay = CIFilter.overlayBlendMode()
        overlay.inputImage = gray
        overlay.backgroundImage = image
        return overlay.outputImage ?? image
    }

    // MARK: - 渲染为 UIImage（用于导出 / 预览静态图）
    func render(_ image: CIImage, from original: UIImage? = nil) -> UIImage? {
        guard let cg = context.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    private func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(v, lo), hi)
    }
}
