import Foundation
import StoreKit

// MARK: - 订阅 / 付费管理
/// 免费开放 3 款基础 GR LUT；订阅解锁全部 LUT + 批量导入 + 无水印。
/// 说明：本交付为可编译工程，默认以「本地模拟订阅」实现，便于真机直接体验。
/// 上架前把下方 `useStoreKit` 改为 true 并配置 StoreKit Configuration（见 README）。
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    /// 是否解锁全部（订阅生效）
    @Published var isUnlocked: Bool = false
    /// 是否仍显示水印（未订阅时免费版带 GR 水印）
    var watermarkEnabled: Bool { !isUnlocked }

    private let key = "grroll.unlocked"

    init() {
        isUnlocked = UserDefaults.standard.bool(forKey: key)
    }

    /// 某款 LUT 是否可用（免费款始终可用；付费款需订阅）
    func isAvailable(_ look: FilmLook) -> Bool {
        !look.isPremium || isUnlocked
    }

    // MARK: - 购买 / 恢复（本地模拟）
    // 上架接入 StoreKit 2：见 README「订阅接入」一节
    func purchase() async {
        // TODO: StoreKit 2 实际购买逻辑
        unlockLocal()
    }

    func restore() async {
        // TODO: StoreKit 2 实际恢复逻辑
        unlockLocal()
    }

    private func unlockLocal() {
        isUnlocked = true
        UserDefaults.standard.set(true, forKey: key)
    }

    /// 仅供测试 / 演示：重置为未订阅
    func resetForDebug() {
        isUnlocked = false
        UserDefaults.standard.set(false, forKey: key)
    }
}
