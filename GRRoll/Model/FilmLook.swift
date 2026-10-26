import Foundation

// MARK: - 用户可调参数
/// 每一款 LUT 都允许独立微调这些参数，复刻理光机内可调项
struct LookParameters: Codable, Equatable {
    /// 颗粒强度 0...1
    var grain: Double = 0.30
    /// 颗粒大小：1.0 细腻，越低越粗（0.4 起）
    var grainSize: Double = 1.0
    /// 暗角 0...1
    var vignette: Double = 0.25
    /// 褪色（胶片灰雾 / 抬起黑位）0...1
    var fade: Double = 0.20
    /// 锐度 0...1
    var sharpness: Double = 0.30
    /// 对比度倍率 0.5...1.5（相对基础值）
    var contrast: Double = 1.0
    /// 饱和度倍率 0...1.5
    var saturation: Double = 1.0
    /// 亮度微调 -0.2...0.2
    var brightness: Double = 0.0
    /// 轻微漏光 0...1
    var lightLeak: Double = 0.0

    static let `default` = LookParameters()
}

// MARK: - 理光 LUT 影调模型
/// 每一款对应理光 GR 系列标志性影像控制；base* 为出厂基调，运行时再叠加用户微调
struct FilmLook: Identifiable, Codable, Hashable {
    let id: String
    /// 中文名，例如「GR 正片」
    let name: String
    /// 英文 / 机型副标题，例如「POSITIVE」
    let subtitle: String
    /// 是否付费（免费仅开放 3 款基础）
    let isPremium: Bool

    // —— 基础影调（出厂）——
    /// 基础对比度（1.0 中性）
    let baseContrast: Double
    /// 基础饱和度（1.0 中性）
    let baseSaturation: Double
    /// 基础亮度（0 中性）
    let baseBrightness: Double
    /// GR 蓝冷调：>0 阴影偏冷蓝，复刻理光标志性蓝调
    let coolAmount: Double
    /// 色偏（绿/品红）：-1...1
    let tintAmount: Double
    /// 是否黑白
    let mono: Bool
    /// 暖色偏移（电影黄/绿用）：负=偏绿，正=偏黄
    let warmShift: Double
    /// 漏光色相 0...1（仅 lightLeak>0 时生效）
    let leakHue: Double

    // MARK: 全系 LUT 定义
    static let all: [FilmLook] = [
        // —— 免费 3 款基础 ——
        FilmLook(id: "gr_positive", name: "GR 正片", subtitle: "POSITIVE", isPremium: false,
                 baseContrast: 1.12, baseSaturation: 0.92, baseBrightness: 0.02,
                 coolAmount: 0.55, tintAmount: 0.05, mono: false, warmShift: 0.0, leakHue: 0.08),
        FilmLook(id: "gr_negative", name: "GR 负片", subtitle: "NEGATIVE", isPremium: false,
                 baseContrast: 0.94, baseSaturation: 0.86, baseBrightness: 0.05,
                 coolAmount: 0.25, tintAmount: -0.05, mono: false, warmShift: 0.12, leakHue: 0.09),
        FilmLook(id: "gr_retro", name: "GR 怀旧", subtitle: "RETR0", isPremium: false,
                 baseContrast: 0.88, baseSaturation: 0.78, baseBrightness: 0.06,
                 coolAmount: 0.15, tintAmount: 0.10, mono: false, warmShift: 0.30, leakHue: 0.07),

        // —— 付费进阶 ——
        FilmLook(id: "gr_mono", name: "单色黑白", subtitle: "MONOCHROME", isPremium: true,
                 baseContrast: 1.20, baseSaturation: 0.0, baseBrightness: 0.0,
                 coolAmount: 0.0, tintAmount: 0.0, mono: true, warmShift: 0.0, leakHue: 0.0),
        FilmLook(id: "gr_hardmono", name: "硬单色", subtitle: "HARD MONO", isPremium: true,
                 baseContrast: 1.45, baseSaturation: 0.0, baseBrightness: -0.02,
                 coolAmount: 0.0, tintAmount: 0.0, mono: true, warmShift: 0.0, leakHue: 0.0),
        FilmLook(id: "gr_silver", name: "留银冲洗", subtitle: "SILVER RET.", isPremium: true,
                 baseContrast: 1.35, baseSaturation: 0.45, baseBrightness: 0.0,
                 coolAmount: 0.30, tintAmount: -0.10, mono: false, warmShift: 0.0, leakHue: 0.05),
        FilmLook(id: "gr_xpro", name: "正负逆冲", subtitle: "CROSS PRO", isPremium: true,
                 baseContrast: 1.25, baseSaturation: 1.10, baseBrightness: 0.0,
                 coolAmount: 0.0, tintAmount: 0.55, mono: false, warmShift: -0.20, leakHue: 0.30),
        FilmLook(id: "gr_hdf", name: "HDF 柔光", subtitle: "HDF DIFFUSE", isPremium: true,
                 baseContrast: 0.90, baseSaturation: 0.95, baseBrightness: 0.08,
                 coolAmount: 0.35, tintAmount: 0.0, mono: false, warmShift: 0.05, leakHue: 0.06),
        FilmLook(id: "gr_cine_y", name: "电影黄", subtitle: "CINEMA Y", isPremium: true,
                 baseContrast: 1.05, baseSaturation: 0.95, baseBrightness: 0.03,
                 coolAmount: 0.0, tintAmount: 0.0, mono: false, warmShift: 0.55, leakHue: 0.10),
        FilmLook(id: "gr_cine_g", name: "电影绿", subtitle: "CINEMA G", isPremium: true,
                 baseContrast: 1.05, baseSaturation: 0.95, baseBrightness: 0.02,
                 coolAmount: 0.0, tintAmount: 0.0, mono: false, warmShift: -0.55, leakHue: 0.35),
    ]

    /// 免费基础款
    static let freeLooks: [FilmLook] = all.filter { !$0.isPremium }
    /// 默认选中（首启）
    static let `default` = all[0]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: FilmLook, r: FilmLook) -> Bool { l.id == r.id }
}
