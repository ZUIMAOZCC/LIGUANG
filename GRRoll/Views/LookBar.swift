import SwiftUI

// MARK: - 底部 LUT 横滑栏
/// 对标 Dazz：底部横向滑动切换理光 LUT，点选即套用
struct LookBar: View {
    @Binding var selection: FilmLook
    @EnvironmentObject var subscription: SubscriptionManager
    var onLocked: (() -> Void)? = nil

    let looks = FilmLook.all

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(looks) { look in
                    LookChip(look: look,
                             isSelected: selection.id == look.id,
                             locked: !subscription.isAvailable(look)) {
                        if subscription.isAvailable(look) {
                            selection = look
                        } else {
                            onLocked?()
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(
            Rectangle().fill(Theme.background.opacity(0.001)) // 透明但可点
        )
    }
}

private struct LookChip: View {
    let look: FilmLook
    let isSelected: Bool
    let locked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(look.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)
                Text(look.subtitle)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Theme.grBlue.opacity(0.35) : Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? Theme.grBlue : Theme.divider, lineWidth: isSelected ? 1.2 : 0.5)
                    )
            )
            .overlay(alignment: .topTrailing) {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textSecondary)
                        .padding(4)
                }
            }
        }
        .frame(minWidth: 64)
    }
}
