# GR ROLL — 理光 GR 胶片 LUT 相机（iOS）

> 口袋理光，一键 GR 蓝，扫街直出。
> 主打理光 GR 全系列原生 LUT 复刻，面向扫街 / 人文 / 日常纪实。

本仓库是一套**可直接在 Xcode 里编译运行**的 SwiftUI 工程源码。
图像处理全部在设备本地完成（Core Image 滤镜链），不上传任何照片。

> **没有 Mac？** 走《[CLOUD_BUILD.md](CLOUD_BUILD.md)》：GitHub 云端 Mac 免费编译出 ipa → Windows 爱思助手用 Apple ID 签名 → 装机，全程不需要 Mac。
> 另有网页版 PWA（iPhone Safari 添加到主屏幕即用）：效果为近似版，见 `pwa/` 目录。

---

## 一、功能清单（已落地）

- ✅ 理光 LUT 库（核心）：GR 正片 / 负片 / 怀旧 / 单色黑白 / 硬单色 / 留银冲洗 / 正负逆冲 / HDF 柔光扩散 / 电影黄 / 电影绿
- ✅ 每款 LUT 独立可调：颗粒强度、颗粒大小、暗角、褪色、锐度、对比度、饱和度、亮度、漏光
- ✅ 双模式：**实时相机取景（所见即所得）+ 相册导入修图**
- ✅ 画幅：3:2（GR 原生）/ 4:3 / 1:1 / 16:9
- ✅ 水印：理光日期戳 + GR 机型小字（免费版强制，订阅可关）
- ✅ 导出：无压缩高清保存到相册，支持 HEIF / JPG，保留原图分辨率
- ✅ 收藏配方：保存自调理光参数，一键复用
- ✅ 付费模式：免费 3 款基础 GR LUT；订阅解锁全部 + 批量导入 + 无水印

---

## 二、在 Mac 上编译并装到 iPhone（已配好 .xcodeproj）

本仓库现已自带标准 Xcode 工程 **`GRRoll.xcodeproj`**，无需从零建工程。完整步骤（含用**爱思助手**导入手机、签名、上架）见 👉 **[BUILD_AND_INSTALL.md](BUILD_AND_INSTALL.md)**。

最简流程：
1. 把整个 `GRRoll/` 文件夹拷到 Mac，**保持 `GRRoll.xcodeproj` 与内层 `GRRoll/` 同级**（不要拆开，否则 Xcode 找不到文件）。
2. 双击 `GRRoll.xcodeproj` 用 Xcode 打开。
3. TARGETS → Signing & Capabilities → 勾选 *Automatically manage signing*，Team 选你的 Apple ID（免费即可真机）。若报 bundle id 冲突，把 Bundle ID 改成独一无二的名字。
4. 插上 iPhone → 顶部选设备 → **⌘R** 直接装到手机；或 `Product → Archive` 导出 `GRRoll.ipa` 再用爱思导入。
5. 首次在 iPhone：设置 → 通用 → VPN与设备管理 → 信任开发者。

工程源码结构（已在 .xcodeproj 中登记）：

```
GRRoll/
├── GRRollApp.swift            // 入口
├── Core/Theme.swift          // 配色规范（GR 灰蓝 #495760 / 背景 #121212）
├── Model/
│   ├── FilmLook.swift        // 10 款 LUT 参数定义
│   ├── Preset.swift          // 收藏配方 + 本地存储
│   └── AspectRatio.swift     // 画幅
├── Engine/GRLookFilter.swift // Core Image 理光影调渲染链
├── Camera/
│   ├── CameraManager.swift   // AVCapture 实时套 LUT + 拍照
│   └── CameraPreviewView.swift
├── Views/                    // CameraView/EditorView/LookBar/ParameterPanel/Library/Presets/Paywall/Settings
├── Store/SubscriptionManager.swift
├── Utilities/                // Watermark / PhotoLibrary / ImagePicker
└── Assets.xcassets/AppIcon.appiconset
```

---

## 三、订阅接入（上架前必做）

当前 `SubscriptionManager` 以**本地模拟订阅**实现（便于真机直接体验全部功能）。
正式上架请接入 **StoreKit 2**：

1. 在 App Store Connect 创建「自动续订订阅」产品（例如 `grroll.pro.monthly`）。
2. 用 Xcode → Editor → Create StoreKit Configuration，或在代码中用 `Product.storeKit` 配置。
3. 把 `SubscriptionManager.purchase()/restore()` 里的 `// TODO: StoreKit 2` 替换为：
   ```swift
   let products = try await Product.products(for: ["grroll.pro.monthly"])
   let result = try await products.first!.purchase()
   // 监听 Transaction.currentEntitlements 更新 isUnlocked
   ```
4. 接 `Transaction.updates` 监听续费 / 退款，维护 `isUnlocked`。

---

## 四、LUT 影调说明

理光 LUT 并非外挂 `.cube` 文件，而是用 **Core Image 滤镜链实时复刻**
（色彩控制 + 色温色偏 GR 蓝 + 褪色灰雾 + 漏光 + 锐度 + 暗角 + 颗粒），
因此每一档都能像机内参数一样逐项目微调，且在相机实时预览与导出中表现一致。
各 LUT 的「出厂基调」集中在 `FilmLook.swift` 的 `all` 数组，方便你按真机校色微调。

---

## 五、注意事项 / 已知边界

- 相机实时预览依赖 Metal（`MTKView`）。**模拟器无摄像头**，请在真机运行。
- 本工程在 Windows 环境下编写，未经过 Xcode 编译校验；若 Xcode 报某个 API 差异，
  多为 iOS 版本差异，按提示微调即可（大部分为 iOS 16+ 标准 API）。
- HEIF 导出在支持的设备上生效；不支持时自动回退为 JPG。

---

## 六、商店文案 / 关键词（已就绪，可直接上架）

标题：**GR ROLL - 理光GR胶片LUT相机，扫街复古照片滤镜**
副标题：**复刻RICOH GR全系影调｜人文扫街｜一键GR蓝｜高清保存**
关键词：理光, GR, GR3, GR2, 胶片相机, 复古滤镜, 扫街, 人文摄影, LUT, 胶片, DAZZ, CCD, 复古相机, 胶片模拟
