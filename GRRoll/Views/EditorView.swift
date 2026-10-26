import CoreImage
import SwiftUI

// MARK: - 编辑 / 导出页（拍照后 & 相册导入共用）
/// 实时套 LUT，调参，加水印，高清导出（HEIF / JPG），本地运算不上传
struct EditorView: View {
    let original: UIImage
    @State var look: FilmLook
    @State var params: LookParameters
    @State var ratio: CaptureRatio
    var source: EditorSource

    @State private var showParams = false
    @State private var showPaywall = false
    @State private var previewImage = UIImage()
    @State private var isSaving = false
    @State private var toast: String? = nil
    @State private var saveFormat: SaveFormat = .jpg
    @State private var wmDate = true
    @State private var wmModel = true

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var presetStore: PresetStore

    private let filter = GRLookFilter()

    init(original: UIImage, look: FilmLook, params: LookParameters,
         ratio: CaptureRatio, source: EditorSource) {
        self.original = original
        self.source = source
        _look = State(initialValue: look)
        _params = State(initialValue: params)
        _ratio = State(initialValue: ratio)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                GeometryReader { _ in
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                }
                controlsPanel
                LookBar(selection: $look, onLocked: { showPaywall = true })
                    .background(Theme.surface)
            }
        }
        .overlay(alignment: .top) { savingToast }
        .sheet(isPresented: $showParams) { ParameterPanel(params: $params) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onChange(of: look) { _ in renderPreview() }
        .onChange(of: params) { _ in renderPreview() }
        .onChange(of: ratio) { _ in renderPreview() }
        .onAppear { renderPreview() }
    }

    // MARK: 顶栏
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").foregroundColor(Theme.textPrimary)
            }
            Spacer()
            Text(look.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Button {
                if isSaving { return }
                saveCurrent()
            } label: {
                if isSaving {
                    ProgressView().tint(Theme.accent)
                } else {
                    Text("保存").font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.accent)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Theme.surface)
    }

    // MARK: 底部控制（画幅 / 格式 / 水印 / 参数）
    private var controlsPanel: some View {
        VStack(spacing: 12) {
            // 画幅
            HStack(spacing: 8) {
                ForEach(CaptureRatio.allCases) { r in
                    Button {
                        ratio = r
                    } label: {
                        Text(r.label)
                            .font(.system(size: 12, weight: ratio == r ? .semibold : .regular))
                            .foregroundColor(ratio == r ? Theme.textPrimary : Theme.textSecondary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(
                                Capsule().fill(ratio == r ? Theme.grBlue.opacity(0.35) : Theme.surface2)
                            )
                    }
                }
                Spacer()
                Button { showParams = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Theme.accent)
                        .padding(8)
                        .background(Circle().fill(Theme.surface2))
                }
            }

            // 格式 + 水印
            HStack {
                Picker("格式", selection: $saveFormat) {
                    Text("JPG").tag(SaveFormat.jpg)
                    Text("HEIF").tag(SaveFormat.heif)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)

                Spacer()

                Toggle("日期", isOn: dateBinding).toggleStyle(.button).tint(Theme.grBlue)
                Toggle("机型", isOn: modelBinding).toggleStyle(.button).tint(Theme.grBlue)
            }
            .font(.system(size: 12))
            .foregroundColor(Theme.textSecondary)

            if !subscription.isUnlocked {
                Text("免费版带 GR 水印 · 订阅可去除")
                    .font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
            }
            Button { savePreset() } label: {
                Text("存为配方").font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Capsule().fill(Theme.surface2))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.surface)
    }

    // 免费版水印强制开启，订阅后可自由开关
    private var dateBinding: Binding<Bool> {
        Binding(get: { subscription.isUnlocked ? wmDate : true },
                set: { if subscription.isUnlocked { wmDate = $0 } })
    }
    private var modelBinding: Binding<Bool> {
        Binding(get: { subscription.isUnlocked ? wmModel : true },
                set: { if subscription.isUnlocked { wmModel = $0 } })
    }

    // MARK: 预览渲染（降采样以流畅）
    private func renderPreview() {
        guard let cg = original.cgImage else { return }
        let ci = CIImage(cgImage: cg)
        let graded = filter.apply(ci, look: look, params: params)
        let cropped = cropToRatio(graded, ratio: ratio.value)
        let maxSide: CGFloat = 1400
        let s = min(1, maxSide / max(cropped.extent.width, cropped.extent.height))
        let previewCI = cropped.transformed(by: CGAffineTransform(scaleX: s, y: s))
        if let out = filter.render(previewCI) { previewImage = out }
    }

    // MARK: 导出（全分辨率）
    private func buildFinal() -> UIImage? {
        guard let cg = original.cgImage else { return nil }
        let ci = CIImage(cgImage: cg)
        let graded = filter.apply(ci, look: look, params: params)
        let cropped = cropToRatio(graded, ratio: ratio.value)
        guard let outCG = filter.context.createCGImage(cropped, from: cropped.extent) else { return nil }
        var img = UIImage(cgImage: outCG, scale: original.scale, orientation: original.imageOrientation)
        let opts = WatermarkRenderer.Options(showDate: effectiveWatermark().date,
                                            showModel: effectiveWatermark().model,
                                            modelName: "RICOH GR", date: Date())
        if opts.showDate || opts.showModel { img = WatermarkRenderer.apply(to: img, options: opts) }
        return img
    }

    private func effectiveWatermark() -> (date: Bool, model: Bool) {
        if !subscription.isUnlocked { return (true, true) }
        return (wmDate, wmModel)
    }

    private func savePreset() {
        let p = Preset(name: look.name + " 配方", lookId: look.id, params: params)
        presetStore.add(p)
        toast = "已存为配方"
    }

    private func saveCurrent() {
        guard let img = buildFinal() else { toast = "导出失败"; return }
        isSaving = true
        let toSave: UIImage
        if saveFormat == .heif,
           let ci = CIImage(image: img),
           let data = filter.context.heifRepresentation(of: ci, format: .RGBA8,
                                                       colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:]),
           let heif = UIImage(data: data) {
            toSave = heif
        } else {
            toSave = img
        }
        PhotoLibrary.save(toSave) { res in
            isSaving = false
            switch res {
            case .success: toast = "已保存到相册"
            case .failure(let e): toast = e.localizedDescription
            }
        }
    }

    @ViewBuilder private var savingToast: some View {
        if let toast {
            Text(toast)
                .font(TypeStyle.caption).foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(Theme.surface.opacity(0.95)))
                .padding(.top, 70)
                .transition(.opacity)
                .onAppear { DispatchQueue.main.asyncAfter(deadline: .now()+1.8) { self.toast = nil } }
        }
    }
}

// MARK: - 辅助
enum SaveFormat: String, CaseIterable { case jpg, heif }
enum EditorSource { case camera, library }

extension View {
    /// 居中裁剪到指定宽高比（保持原图朝向）
    func cropToRatio(_ image: CIImage, ratio: CGFloat) -> CIImage {
        let w = image.extent.width, h = image.extent.height
        let r = w >= h ? ratio : 1.0 / ratio
        let current = w / h
        let crop: CGRect
        if current > r {
            let nw = h * r
            crop = CGRect(x: (w-nw)/2, y: 0, width: nw, height: h)
        } else {
            let nh = w / r
            crop = CGRect(x: 0, y: (h-nh)/2, width: w, height: nh)
        }
        return image.cropped(to: crop)
    }
}
