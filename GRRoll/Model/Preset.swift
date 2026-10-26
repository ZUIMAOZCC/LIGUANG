import Foundation

// MARK: - 收藏配方
/// 用户调好的理光参数组合，可一键复用
struct Preset: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    /// 基于哪款 LUT
    var lookId: String
    /// 微调参数
    var params: LookParameters
    /// 创建时间
    var createdAt: Date

    init(name: String, lookId: String, params: LookParameters) {
        self.id = UUID().uuidString
        self.name = name
        self.lookId = lookId
        self.params = params
        self.createdAt = Date()
    }

    var look: FilmLook? { FilmLook.all.first { $0.id == lookId } }
}

// MARK: - 配方存储（本地 UserDefaults，不上传）
final class PresetStore: ObservableObject {
    static let shared = PresetStore()
    @Published var presets: [Preset] = []
    /// 从「配方」页点击「应用」后，相机页启动时自动套用
    @Published var pending: Preset? = nil

    private let key = "grroll.presets"

    init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([Preset].self, from: data) else { return }
        presets = list
    }

    func save() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func add(_ preset: Preset) { presets.append(preset); save() }
    func remove(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }; save()
    }
    func rename(_ preset: Preset, to name: String) {
        if let i = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[i].name = name; save()
        }
    }
}
