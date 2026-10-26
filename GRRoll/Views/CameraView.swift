import SwiftUI

// MARK: - 相机主页面（打开即拍）
struct CameraView: View {
    @StateObject private var manager = CameraManager()
    @State private var selection: FilmLook = .default
    @State private var params: LookParameters = .default
    @State private var ratio: CaptureRatio = .r3x2

    @State private var showParams = false
    @State private var showPaywall = false
    @State private var showImport = false
    @State private var lastShot: UIImage? = nil
    @State private var editorTarget: (image: UIImage, look: FilmLook, params: LookParameters, ratio: CaptureRatio)? = nil

    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var presetStore: PresetStore

    var body: some View {
        ZStack {
            CameraPreviewView(manager: manager).ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomArea
            }
            .padding(.bottom, 8)
        }
        .onAppear {
            if let p = presetStore.pending, let look = p.look {
                selection = look; params = p.params; presetStore.pending = nil
            }
            manager.start()
        }
        .onDisappear { manager.stop() }
        .onChange(of: selection) { manager.currentLook = $0 }
        .onChange(of: params) { manager.params = $0 }
        .onChange(of: ratio) { manager.ratio = $0 }
        .sheet(isPresented: $showParams) { ParameterPanel(params: $params) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showImport) {
            ImagePicker { img in
                if let img { editorTarget = (img, selection, params, ratio) }
            }
        }
        .fullScreenCover(item: editorBinding) { target in
            EditorView(original: target.image, look: target.look,
                       params: target.params, ratio: target.ratio, source: .camera)
        }
    }

    // fullScreenCover 需要 Identifiable；用 Binding 适配
    private var editorBinding: Binding<EditorTarget?> {
        Binding(
            get: { editorTarget.map { EditorTarget(image: $0.image, look: $0.look, params: $0.params, ratio: $0.ratio) } },
            set: { editorTarget = $0.map { ($0.image, $0.look, $0.params, $0.ratio) } }
        )
    }

    // MARK: 顶栏：画幅 + 参数
    private var topBar: some View {
        HStack {
            Menu {
                ForEach(CaptureRatio.allCases) { r in
                    Button { ratio = r } label: { Label(r.label + (r.isGRNative ? "（GR 原生）" : ""), systemImage: "rectangle") }
                }
            } label: {
                Label(ratio.label, systemImage: "rectangle.on.rectangle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(Theme.surface.opacity(0.7)))
            }
            Spacer()
            Button { showParams = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(Theme.textPrimary)
                    .padding(10)
                    .background(Circle().fill(Theme.surface.opacity(0.7)))
            }
        }
        .padding(.horizontal, 16).padding(.top, 12)
    }

    // MARK: 底部：LUT 栏 + 快门 + 导入
    private var bottomArea: some View {
        VStack(spacing: 12) {
            LookBar(selection: $selection, onLocked: { showPaywall = true })
                .background(Theme.surface)
            HStack(spacing: 24) {
                // 上次拍摄缩略图（点开编辑）
                Button {
                    if let s = lastShot { editorTarget = (s, selection, params, ratio) }
                } label: {
                    if let s = lastShot {
                        Image(uiImage: s).resizable().scaledToFill()
                            .frame(width: 42, height: 42).clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8).fill(Theme.surface)
                            .frame(width: 42, height: 42)
                    }
                }
                .frame(width: 42, height: 42)

                // 快门
                Button {
                    manager.takePhoto { img in
                        guard let img else { return }
                        lastShot = img
                        editorTarget = (img, selection, params, ratio)
                    }
                } label: {
                    Circle()
                        .strokeBorder(Theme.textPrimary, lineWidth: 4)
                        .background(Circle().fill(Theme.textPrimary.opacity(0.15)))
                        .frame(width: 66, height: 66)
                        .overlay(Circle().fill(Theme.textPrimary).frame(width: 52, height: 52))
                }

                // 相册导入（右下角）
                Button {
                    showImport = true
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Theme.surface.opacity(0.7)))
                }
                .frame(width: 42, height: 42)
            }
        }
    }
}

// MARK: - fullScreenCover 用的 Identifiable 包装
private struct EditorTarget: Identifiable {
    let id = UUID()
    let image: UIImage
    let look: FilmLook
    let params: LookParameters
    let ratio: CaptureRatio
}
