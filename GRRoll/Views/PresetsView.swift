import SwiftUI

// MARK: - 收藏配方
struct PresetsView: View {
    @EnvironmentObject var store: PresetStore
    @EnvironmentObject var subscription: SubscriptionManager
    @State private var showPaywall = false

    var body: some View {
        NavigationView {
            List {
                if store.presets.isEmpty {
                    Text("还没有收藏配方。在编辑页点「存为配方」即可保存你的理光参数。")
                        .font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
                }
                ForEach(store.presets) { p in
                    row(p)
                }
                .onDelete { offsets in
                    let toRemove = offsets.map { store.presets[$0] }
                    toRemove.forEach { store.remove($0) }
                }
            }
            .navigationTitle("我的配方")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .toolbar { EditButton().foregroundColor(Theme.accent) }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func row(_ p: Preset) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(p.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.textPrimary)
                Spacer()
                Button("应用") {
                    if let look = p.look, !subscription.isAvailable(look) { showPaywall = true; return }
                    store.pending = p
                }
                .foregroundColor(Theme.accent)
            }
            if let look = p.look {
                Text(look.name + " · " + look.subtitle)
                    .font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
            }
            Text(paramsSummary(p.params))
                .font(TypeStyle.caption).foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 6)
    }

    private func paramsSummary(_ pa: LookParameters) -> String {
        String(format: "颗粒 %.2f · 暗角 %.2f · 褪色 %.2f · 锐度 %.2f",
               pa.grain, pa.vignette, pa.fade, pa.sharpness)
    }
}
