# 给 Claude 的项目说明

- 开工前先读 `PLAN.md`，那里是目标、原则和最新进度；完成一项就更新它。
- 用户主要用手机看，回复用中文，简洁。
- 手感第一：键盘扩展里不要用 SwiftUI 渲染按键，用 UIKit；按下（touchDown）就响应；Rime 调用放后台串行队列，UI 主线程只做绘制。
- 键盘扩展内存很紧（约 60–70MB 上限），避免大对象常驻。
- 本机是 Linux，无法运行 Xcode；所有编译都在 GitHub Actions 的 macOS runner 上完成，改完代码推送后看 Actions 结果。
- 靛蓝只用在首选候选、发送键、按下高亮三处。
