import SwiftUI

// MARK: - 颜色扩展（十六进制）
extension Color {
    /// 用十六进制整数构造颜色，例如 Color(hex: 0x495760)
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - 主题 / 品牌色
/// GR ROLL 视觉规范
/// 主色：理光 GR 灰蓝 #495760；背景深色 #121212；文字浅灰
enum Theme {
    /// 理光 GR 灰蓝（品牌主色）
    static let grBlue      = Color(hex: 0x495760)
    /// 深背景
    static let background   = Color(hex: 0x121212)
    /// 卡片 / 面板表面
    static let surface      = Color(hex: 0x1C1F22)
    /// 次级表面（滑块轨道等）
    static let surface2     = Color(hex: 0x2A2E33)
    /// 主文字（浅灰）
    static let textPrimary  = Color(hex: 0xE8E8E8)
    /// 次要文字
    static let textSecondary = Color(hex: 0x9AA0A6)
    /// 强调 / 高亮（淡 GR 蓝）
    static let accent       = Color(hex: 0x6E8190)

    /// 分隔线
    static let divider      = Color(hex: 0x2E3338)
}

// MARK: - 全局字号规范（SF / 系统字体）
enum TypeStyle {
    static let title    = Font.system(size: 22, weight: .semibold, design: .default)
    static let body     = Font.system(size: 15, weight: .regular, design: .default)
    static let caption  = Font.system(size: 12, weight: .regular, design: .default)
    static let mono     = Font.system(size: 12, weight: .medium, design: .monospaced)
}
