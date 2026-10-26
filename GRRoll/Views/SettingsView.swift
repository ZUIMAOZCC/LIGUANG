import SwiftUI

// MARK: - 设置
struct SettingsView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @State private var showPaywall = false

    var body: some View {
        NavigationView {
            List {
                Section("会员") {
                    HStack {
                        Text("状态")
                        Spacer()
                        Text(subscription.isUnlocked ? "已订阅 PRO" : "免费版")
                            .foregroundColor(Theme.textSecondary)
                    }
                    if !subscription.isUnlocked {
                        Button("升级 GR ROLL PRO") { showPaywall = true }
                            .foregroundColor(Theme.accent)
                    }
                    Button("恢复购买") { Task { await subscription.restore() } }
                        .foregroundColor(Theme.accent)
                }
                Section("关于") {
                    Text("GR ROLL").font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.textPrimary)
                    Text("口袋理光，一键 GR 蓝，扫街直出").font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
                    Text("版本 1.0.0").foregroundColor(Theme.textSecondary)
                }
                Section("隐私") {
                    Text("所有图像处理均在设备本地完成，不会上传任何照片。")
                        .font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}
