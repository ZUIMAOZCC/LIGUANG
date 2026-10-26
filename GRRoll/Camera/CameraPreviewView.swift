import MetalKit
import SwiftUI

// MARK: - 相机取景预览（Metal 实时渲染）
struct CameraPreviewView: UIViewRepresentable {
    let manager: CameraManager

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        view.framebufferOnly = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.contentMode = .scaleAspectFill
        view.backgroundColor = .black
        manager.attach(metalView: view)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
}
