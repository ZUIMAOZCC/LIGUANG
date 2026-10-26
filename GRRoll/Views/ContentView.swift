import SwiftUI

// MARK: - 主框架
/// 打开默认进入相机页（扫街直出）；底部 Tab 提供 相机 / 相册 / 配方 / 设置
struct ContentView: View {
    @State private var tab: Tab = .camera

    enum Tab: Hashable {
        case camera, library, presets, settings
    }

    var body: some View {
        TabView(selection: $tab) {
            CameraView()
                .tag(Tab.camera)
                .tabItem { Label("拍摄", systemImage: "camera.fill") }

            LibraryView()
                .tag(Tab.library)
                .tabItem { Label("相册", systemImage: "photo.on.rectangle.angled") }

            PresetsView()
                .tag(Tab.presets)
                .tabItem { Label("配方", systemImage: "slider.horizontal.3") }

            SettingsView()
                .tag(Tab.settings)
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .accentColor(Theme.accent)
        .preferredColorScheme(.dark)
    }
}
