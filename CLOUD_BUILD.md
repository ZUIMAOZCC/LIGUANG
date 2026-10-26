# 🚀 GR ROLL 云端编译 + 爱思安装（全程不需要 Mac）

## 原理（先看懂再动手）
- iOS 的 `.ipa` 只能在 **macOS + Xcode** 环境编译。本机是 Windows 出不了，但 **GitHub 免费提供云端 Mac 机器**（GitHub Actions）帮你编译。
- 云端编译出来的是**未签名 ipa**，还装不了手机——最后一步用**爱思助手「IPA 签名」**，用你自己的 Apple ID（免费）签名后即可装到 iPhone。
- 全流程：**GitHub 注册 → 上传代码 → 点一下运行 → 下载 ipa → 爱思签名 → 装机**。

---

## 第一步：注册 GitHub（免费）
1. 浏览器打开 https://github.com → Sign up 注册（邮箱验证即可）。

## 第二步：新建仓库（必须 Public）
1. 登录后点右上角 **＋ → New repository**。
2. Repository name 填：`grroll`（随便，别用中文）。
3. 选 **Public**（重要！Public 仓库用 macOS 云机器免费不限时）。
4. 不勾任何初始化选项 → **Create repository**。

## 第三步：上传工程代码（网页拖拽即可）
1. 在仓库页点 **uploading an existing file** 链接。
2. 打开你电脑的 `D:\ai文件\2026-10-26-15-21-59\GRRoll\` 文件夹，
   **进入这个文件夹内部**，**全选里面所有文件和文件夹**（包括 `GRRoll.xcodeproj`、`GRRoll`、`.github`、pwa、README 等）拖进上传框。
   > ⚠️ 是把 GRRoll **里面的内容**传上去，不是把 GRRoll 文件夹本身传进去（否则目录多一层，编译会找不到工程）。
3. 等上传完（`GRRoll.xcodeproj` 是文件夹，网页上传会保留结构）→ 底下点 **Commit changes**。

> **⚠️ 检查 `.github` 是否传上去了**：传完在仓库首页应能看到 `.github` 文件夹。
> 如果列表里没有它（个别浏览器会跳过点开头的文件夹），手动补：
> 仓库页 → **Add file → Create new file** → 文件名输入 `.github/workflows/build.yml`，
> 然后把你电脑 `GRRoll\.github\workflows\build.yml` 的内容全部复制粘贴进去 → Commit changes。

## 第四步：运行云端编译
1. 仓库顶部点 **Actions** 标签。
2. 左侧选 **Build GR ROLL ipa** → 右侧 **Run workflow** → 绿色按钮确认。
3. 等待约 3–8 分钟。任务转 **绿勾 ✓** 即成功。
   - 若出现 **红叉 ✗**：点进去把红色报错日志（尤其 `xcodebuild` 那一步的最后几十行）复制发给 AI，我来修工程。

## 第五步：下载 ipa
1. 点进成功的那次运行，拉到底部 **Artifacts** 区域。
2. 下载 **GRRoll-unsigned-ipa**（是个 zip），解压得到 **`GRRoll-unsigned.ipa`**，放到电脑桌面备用。

## 第六步：爱思签名并安装到 iPhone（Windows）
1. iPhone 用数据线连电脑，爱思助手里信任此电脑。
2. 爱思助手 → **应用游戏 → IPA 签名**：
   - 添加刚下载的 `GRRoll-unsigned.ipa`
   - 勾选 **使用 Apple ID 签名**，输入你的 Apple ID 账号和密码（免费账号即可）
   - 开始签名 → 得到 **`GRRoll-signed.ipa`**
3. 爱思助手 → **应用游戏 → 导入安装** → 选签名后的 ipa → 装进手机。

## 第七步：手机上信任开发者（首次必做）
iPhone：**设置 → 通用 → VPN与设备管理** → 找到你的 Apple ID（开发者 App）→ 点**信任**。
然后回桌面打开 **GR ROLL**，允许相机权限，即可使用。

---

## ⚠️ 免费方案的限制（先知道，免得疑惑）
| 项目 | 限制 |
|---|---|
| 免费 Apple ID 签名有效期 | **7 天**，到期后重新爱思签名安装一次即可 |
| 免费 Apple ID 设备数 | 同一证书最多 **3 台** iPhone / 10 个 App |
| 云端编译 | Public 仓库免费不限时；Private 仓库每月 2000 分钟（够用） |
| 真·手动曝光（快门/ISO） | 原生 App 才可控，装上后我可以在源码里继续加 |
| 上架 App Store | 需 Apple Developer Program（$99/年），另说 |

## ❓ 常见问题
- **编译红叉**：把 Actions 日志发 AI 修复，很常见（工程第一次真实编译），别慌。
- **爱思签名失败**：确认 Apple ID 未开两步验证锁死；或换"Sideloadly"（Windows 另一款签名工具）重试。
- **安装后闪退/打不开**：多半是没做第七步「信任开发者」。
- **想换图标/名字**：改完代码重新推到 GitHub，再跑一次 Actions 即可。
