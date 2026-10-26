import SwiftUI

// MARK: - 参数滑块面板（右侧弹出）
/// 独立调节颗粒强度 / 颗粒大小 / 暗角 / 褪色 / 锐度 / 对比度 / 饱和度 / 亮度 / 漏光
struct ParameterPanel: View {
    @Binding var params: LookParameters
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    Group {
                        slider("颗粒强度", value: $params.grain, range: 0...1, fmt: "%.2f")
                        slider("颗粒大小", value: $params.grainSize, range: 0.4...2.0, fmt: "%.2f",
                               hint: "数值越小颗粒越粗")
                        slider("暗角", value: $params.vignette, range: 0...1, fmt: "%.2f")
                        slider("褪色 / 灰雾", value: $params.fade, range: 0...1, fmt: "%.2f")
                        slider("锐度", value: $params.sharpness, range: 0...1, fmt: "%.2f")
                    }
                    Divider().background(Theme.divider)
                    Group {
                        slider("对比度", value: $params.contrast, range: 0.5...1.5, fmt: "%.2f")
                        slider("饱和度", value: $params.saturation, range: 0...1.5, fmt: "%.2f")
                        slider("亮度", value: $params.brightness, range: -0.2...0.2, fmt: "%.2f")
                        slider("漏光", value: $params.lightLeak, range: 0...1, fmt: "%.2f")
                    }
                    Button("重置为默认") {
                        params = .default
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .padding(.top, 6)
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("参数微调")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        fmt: String, hint: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(TypeStyle.body).foregroundColor(Theme.textPrimary)
                Spacer()
                Text(String(format: fmt, value.wrappedValue))
                    .font(TypeStyle.mono).foregroundColor(Theme.textSecondary)
            }
            Slider(value: value, in: range)
                .accentColor(Theme.grBlue)
            if let hint {
                Text(hint).font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
            }
        }
    }
}
