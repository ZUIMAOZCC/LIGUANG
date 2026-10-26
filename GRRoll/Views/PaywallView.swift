import SwiftUI

// MARK: - 付费墙
/// 免费开放 3 款基础 GR LUT；订阅解锁全部 LUT + 批量导入 + 无水印
struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscription: SubscriptionManager
    @State private var busy = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("GR ROLL PRO")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text("解锁全套理光 GR 原生 LUT")
                            .font(TypeStyle.body).foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top, 16)

                    featureRow("全部 10 款理光 LUT", "正片/负片/怀旧/单色/留银冲洗/HDF/电影黄绿…")
                    featureRow("批量导入修图", "一次处理多张相册照片")
                    featureRow("无水印导出", "干净的扫街直出")
                    featureRow("持续更新", "跟随理光新机型影调")

                    Button {
                        Task {
                            busy = true
                            await subscription.purchase()
                            busy = false
                            dismiss()
                        }
                    } label: {
                        if busy {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity).padding(14)
                                .background(Theme.grBlue).cornerRadius(12)
                        } else {
                            Text("订阅解锁 · ¥18/月")
                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(14)
                                .background(Theme.grBlue).cornerRadius(12)
                        }
                    }

                    Button {
                        Task { await subscription.restore(); dismiss() }
                    } label: {
                        Text("恢复购买").font(.system(size: 14)).foregroundColor(Theme.accent)
                    }

                    Text("免费已开放：GR 正片 / GR 负片 / GR 怀旧")
                        .font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("升级 GR ROLL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }.foregroundColor(Theme.accent)
                }
            }
        }
    }

    private func featureRow(_ title: String, _ sub: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.grBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(TypeStyle.body).foregroundColor(Theme.textPrimary)
                Text(sub).font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
