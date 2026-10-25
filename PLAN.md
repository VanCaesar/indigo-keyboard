# 靛蓝输入法（暂名）· 项目计划

## 目标
做一款 iOS 中文输入法：手感接近原生、比紫毫更跟手，以后再加 AI 功能。主色是靛蓝。

## 背景
紫毫（基于 Rime + 雾凇拼音）功能不错，但不跟手、慢半拍，没有滑动输入，震动不如原生。
我们用同样的底层，重点把键盘本身做好。

## 设计原则
1. **手感第一**：按下就响应，不等抬起；拼音运算放后台线程。任何新功能只要拖慢手感，就不加。
2. **离线打底**：打字完全在本地，只有主动点 AI 才联网。
3. **颜色克制**：靛蓝只用在首选候选词、发送键、按下高亮三处，其余保持系统灰白。
   - 浅色 `#5B54C9`，深色 `#8B85E6`（暂定）

## 版本规划
- **v0.1 手感版**：Rime + 雾凇拼音、26 键全拼、震动、深浅色靛蓝主题。目标：能当日常输入法用。
- **v0.2 AI 版**：润色、翻译、改语气、续写，先预览再替换。模型待定。
- **v0.3 滑行版**：中英文滑动输入。
- **以后**：中英混打、剪贴板历史、常用短语、可选主题。
- **不做**：九宫格、双拼（只用全拼）。

## 技术方案
- Swift + UIKit 键盘扩展，外加一个主 App（引导开启键盘、设置）
- 输入引擎：librime + 雾凇拼音（rime-ice）
- 震动需要"完全访问"
- 编译：GitHub Actions 的 macOS runner（本仓库为公开仓库，免费）
- 安装：开发者账号搞定前，用 Sideloadly + 免费 Apple ID 侧载（每 7 天重签）；搞定后改走 TestFlight

## 分工
- Claude：写全部代码和编译配置，推送到本仓库
- 用户：真机试用、反馈手感，处理需要本人操作的账号事项

## 当前状态
- [x] GitHub 仓库：VanCaesar/indigo-keyboard
- [ ] Apple 开发者账号：中国身份证 + 国区 Apple ID 注册，身份验证失败，待联系开发者支持（developer.apple.com/contact）。注册全程不要换设备、不要反复重试。
- [ ] v0.1（开发分支 `claude/v0.1`）
  - [x] 工程骨架：XcodeGen（`project.yml`）生成主 App `Indigo` + 键盘扩展 `IndigoKeyboard`，Swift + UIKit，iOS 16+
  - [x] CI：`.github/workflows/build.yml`，macOS runner 编译，产物 `Indigo-unsigned-ipa`（Actions 页面下载）
  - [ ] librime + 雾凇拼音：CI 从源码编 librime 1.17.0（iOS arm64 静态库）+ 本机 rime_deployer，预编译雾凇词库打进键盘扩展；键盘里不部署
  - [ ] 26 键全拼布局、候选栏、按下即响应、震动、深浅色靛蓝主题

## 技术备忘
- librime：`scripts/build-librime.sh`，无 glog、无插件（暂无 lua，用雾凇自带的 no_lua 方案）；产物缓存于 Actions cache
- 词库：`scripts/build-rime-data.sh`，只编 rime_ice（含 melt_eng、radical_pinyin），设置在 `Rime/default.custom.yaml`
- 运行时：shared_data_dir = 扩展包内只读 `RimeData/`（预编译在 `RimeData/build/`），user_data_dir = 扩展容器 `Application Support/Rime`（用户词频）
