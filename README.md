# 靛蓝输入法（indigo-keyboard）

iOS 中文输入法：Rime + 雾凇拼音，UIKit 键盘，按下即响应。计划与进度见 [PLAN.md](PLAN.md)。

## 下载安装（侧载）
1. 打开 GitHub 本仓库 → Actions → 最新一次成功的 Build → 页面底部 Artifacts 下载 `Indigo-unsigned-ipa`（zip 里是 IPA）
2. 用 Sideloadly + Apple ID 安装（免费账号 7 天重签）
3. 设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 靛蓝；点进去打开「允许完全访问」（震动需要）

## 编译
只在 GitHub Actions 的 macOS runner 上编译（`.github/workflows/build.yml`）：
- `scripts/build-librime.sh`：从源码编 librime（iOS 静态库 + 本机 rime_deployer）
- `scripts/build-rime-data.sh`：预编译雾凇拼音词库
- `xcodegen generate` 生成工程后 `xcodebuild`，打包未签名 IPA
