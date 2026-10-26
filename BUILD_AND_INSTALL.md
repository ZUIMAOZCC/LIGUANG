# GR ROLL 编译与安装指南（Xcode → 爱思助手）

本指南教你如何把 `GRRoll.xcodeproj` 在 Mac 上编译成可用的 App，并**用爱思助手导入 iPhone**。
（如果你只想要"今天就能在手机上玩"的版本，而暂时没有 Mac，见文末「没有 Mac 怎么办」。）

---

## 一、你需要准备

| 物品 | 说明 |
|---|---|
| Mac 一台 | macOS 13+ 推荐，装 **Xcode 15**（App Store 免费） |
| iPhone 一台 | iOS 16.0 及以上 |
| 数据线 | 连 Mac 与 iPhone，首次信任电脑 |
| 爱思助手 | Windows / Mac 版均可，官网 https://www.i4.cn |
| Apple ID | **免费即可**真机安装；想上架 App Store 再买 $99/年开发者 |

> 注意：本工程是 **SwiftUI + AVFoundation + Metal** 原生项目，**模拟器没有摄像头**，
> 实时取景与拍照必须在真机测试。模拟器跑会黑屏/报错，属正常现象。

---

## 二、把工程拷到 Mac并保持目录结构

整个文件夹拷到 Mac 后，目录结构必须保持如下（**`GRRoll.xcodeproj` 与内层 `GRRoll/` 是同级兄弟**，不要拆开，否则 Xcode 找不到源文件）：

```
GRRoll/                         ← 你拷到 Mac的这个根文件夹
├── GRRoll.xcodeproj/           ← 双击它打开（已配好，别改名字）
├── GRRoll/                     ← 源码与资源（别改名字）
│   ├── GRRollApp.swift
│   ├── Core / Model / Engine / Camera / Views / Store / Utilities
│   ├── Assets.xcassets/AppIcon.appiconset
│   └── Info.plist
├── store_assets/               ← 上架宣传图（可选，不影响编译）
├── README.md
└── generate_xcodeproj.py       ← 重生成工程的脚本（可选）
```

传输方式任选：U 盘、微信文件传输助手、AirDrop、网盘。

---

## 三、在 Xcode 里配置签名并编译

1. **双击 `GRRoll.xcodeproj`** 用 Xcode 打开。
2. 左侧点最顶上的蓝色 **GRRoll** 工程图标 → 中间切到 **TARGETS → GRRoll → Signing & Capabilities**。
3. 勾选 **Automatically manage signing**。
4. **Team** 这一栏点下拉 → **Add an Account…** → 登录你的 Apple ID（免费个人账号即可）。
   登录后回到 Team 选你的个人账户（形如 `你的名字 (Personal Team)`）。
5. 如果 Xcode 报红字 **"Failed to register bundle identifier" / "unavailable"**：
   说明 `com.grroll.camera` 被占用了。把 **Bundle Identifier** 改成你独有的，例如
   `com.zhangsan.grroll2026`（在 Signing 那一栏直接改，或去 TARGETS → Build Settings 搜 `PRODUCT_BUNDLE_IDENTIFIER`）。
6. 顶部设备选择框（播放按钮右边）**插上 iPhone 后选你的手机**（首次手机弹窗点"信任"，Mac 也信任）。
7. 点 **▶ 运行（⌘R）**。第一次会编译几十秒，然后自动装到手机并打开。
   - 若提示 "iPhone is busy / 不受信任的设备"：手机上 设置 → 通用 → VPN与设备管理 → 信任该开发者，再 ⌘R。
8. **首次打开 App 会请求相机/相册权限**，点允许即可使用取景与导入。

> 至此你已经用 Xcode 把 App 装进手机了。想走**爱思导入**（比如换台电脑装、或发给朋友），继续第四步导出 `.ipa`。

---

## 四、导出 .ipa（用于爱思导入）

### 方法 1：Xcode Archive 导出（推荐，签名已带好）
1. 顶部设备先选 **Any iOS Device (arm64)**（或你的真机），让 Archive 可用。
2. 菜单 **Product → Archive**（若灰色，确认设备不是模拟器）。
3. 自动弹出 **Organizer**，选中刚生成的包 → **Distribute App**。
4. 选 **Development**（开发分发，免费账号也支持）→ 一路 Next/Export → 选个文件夹。
5. 得到 **`GRRoll.ipa`**（已用你的 Apple ID 签名，可直接装到这台/该账号下的设备）。

### 方法 2：手动打包（账号类型不限，更通用）
1. 完成第三步的 Archive（或 `Product → Build` 后从 DerivedData 取 .app）。
2. 在 Organizer 里右键该 Archive → **Show in Finder** → 右键 `.xcarchive` → **显示包内容**
   → `Products/Applications/GRRoll.app`。
3. 桌面新建文件夹，命名为 **`Payload`**（必须叫这个），把 `GRRoll.app` 拖进去。
4. 右键 `Payload` 文件夹 → 压缩成 `Payload.zip` → 改名成 **`GRRoll.ipa`**（直接改后缀）。

> `Payload` 文件夹 + `.app` 压缩改名，是 iOS 安装包的通用做法，爱思认这个结构。

---

## 五、用爱思助手导入手机

1. 电脑打开 **爱思助手**，用数据线连上 iPhone（首次允许"信任此电脑"）。
2. **方式 A（.ipa 已签名，最常见）**：
   左侧「我的设备」→「应用游戏」→ 点 **「导入安装」** → 选刚才的 `GRRoll.ipa` → 等进度条走完即安装成功。
3. **方式 B（.ipa 没签名 / 换了设备 / 签名过期）**：
   - 爱思顶栏 → **「工具箱」→「IPA 签名」**（或在导入安装时勾选"使用 Apple ID 签名"）。
   - 添加你的 Apple ID（免费即可）→ 选它给 `GRRoll.ipa` 签名 → 再安装。
   - 免费 Apple ID 签名**有效期 7 天**，到期后在爱思里重新签名一次即可。
4. 手机上：设置 → 通用 → VPN与设备管理 → 找到你的 Apple ID → **信任**。
5. 桌面出现 **GR ROLL** 图标，打开即用。

> 小提示：如果你的 iPhone 已经用 Xcode ⌘R 装过，爱思再装同名同 Bundle ID 的包会覆盖，正常现象。

---

## 六、常见问题排查

| 现象 | 解决 |
|---|---|
| 模拟器黑屏/取景报错 | 正常，**必须用真机**测相机 |
| Xcode 报 "No account for team" | Xcode → Settings → Accounts 登录 Apple ID |
| 报 bundle id 不可用 | 把 Bundle ID 改成独一无二的，如 `com.你名字.grroll` |
| 真机 ⌘R 装不上，提示设备不受信任 | iPhone：设置 → 通用 → VPN与设备管理 → 信任开发者 |
| 爱思提示"应用签名无效/已过期" | 免费签名 7 天到期，爱思「IPA 签名」重签一次 |
| 爱思导入后打开闪退 | 多半是没在手机"信任"开发者，去 VPN与设备管理 信任；或重签 |
| 拍照/导出无反应 | 检查是否点了"允许"相机与相册权限；首次弹窗别点拒绝 |

---

## 七、想上架 App Store

1. 加入 **Apple Developer Program（$99/年）**。
2. 在 App Store Connect 注册你的 Bundle ID，创建 App 记录，填入 `README.md` 末尾的**标题 / 副标题 / 关键词 / 描述**。
3. Xcode 里 Team 换成**付费开发者账号**，Archive → Distribute → **App Store Connect** 上传。
4. 用 `store_assets/` 里的 4 张宣传图做截图（注意：AI 生成的图右下角带平台水印，仅作排版参考，**上架截图建议用真机实拍替换**）。
5. 订阅功能接入见 `README.md` 第三节（StoreKit 2）。

---

## 八、没有 Mac 怎么办？

如果你现在手头**只有 Windows + iPhone，没有 Mac**，原生 `.ipa` 无法在本环境生成（需要 iOS SDK / Xcode）。
两条替代路：

- **A. 借/用一台 Mac** 走上面第一~五步，这是最稳的正路。
- **B. 用我做的网页版（PWA）**：我可以把 GR ROLL 做成网页版（调用手机摄像头、CSS/Canvas 近似理光 LUT、保存到相册），
  iPhone Safari 里「添加到主屏幕」就能当 App 用，**今天就能玩，无需 Mac/爱思/开发者账号**。
  需要的话告诉我，我直接给你做一个。

---

## 隐私说明

全部图像处理在**设备本地**完成（Core Image + Metal），**不上传任何照片**，无网络请求。
