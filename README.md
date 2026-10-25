# 靛蓝输入法（indigo-keyboard）

iOS 中文输入法：Rime + 雾凇拼音，UIKit 键盘，按下即响应。计划与进度见 [PLAN.md](PLAN.md)。

## 下载安装

### 无线安装（不用连线，免费 Apple ID 每 7 天重签）
1. 第一次：手机拿到 UDID（设备编号），填进爱思助手。
2. 下载未签名包：Releases 里的 `Indigo-unsigned.ipa`（或 Actions → 最新成功的 Build → Artifacts）。
3. 爱思助手 → IPA 签名 → 使用 Apple ID 签名（建议用小号），手动填 UDID，签名。
4. 本仓库 → Releases → Draft a new release，tag 填 `signed-日期`（必须以 `signed` 开头），拖入签好的 IPA → Publish。
5. 等 1–2 分钟，`.github/workflows/pages.yml` 自动更新安装页：手机 Safari 打开 <https://vancaesar.github.io/indigo-keyboard/> 点「安装」。
6. 首次装好后：开发者模式、信任证书、添加键盘并允许完全访问（安装页上有步骤）。

### 连线安装
用 Sideloadly 或爱思助手把 IPA 直接装进手机（免费账号 7 天重签）。

## 编译
只在 GitHub Actions 的 macOS runner 上编译（`.github/workflows/build.yml`）：
- `scripts/build-librime.sh`：从源码编 librime（iOS 静态库 + 本机 rime_deployer）
- `scripts/build-rime-data.sh`：预编译雾凇拼音词库
- `xcodegen generate` 生成工程后 `xcodebuild`，打包未签名 IPA
