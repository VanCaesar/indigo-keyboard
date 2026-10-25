import Foundation

/// 某一时刻的输入状态，交给主线程绘制
struct RimeSnapshot {
    /// 每次状态变化递增；点候选时用它判断候选是否已过期
    var revision = 0
    var commitText: String?
    var preedit = ""
    var candidates: [String] = []
    var isComposing = false
    /// 候选可能还有更多（滑到末尾时再取）
    var mayHaveMore = false
}

/// X11 keysym 与 Rime 掩码
enum RimeKey {
    static let space: Int32 = 0x20
    static let backspace: Int32 = 0xff08
    static let returnKey: Int32 = 0xff0d
    static let escape: Int32 = 0xff1b
    static let shiftMask: Int32 = 1 << 0
}

/// librime 只在这一个后台串行队列上调用；回调一律回到主线程。
final class RimeEngine {
    static let shared = RimeEngine()

    static let schemaId = "rime_ice"
    static let candidateBatch = 60

    private let queue = DispatchQueue(label: "indigo.rime", qos: .userInteractive)
    private let rime = IKRime()
    private var revision = 0

    private init() {}

    /// 加载词库，首次约几百毫秒；期间的按键会排在队列里依次处理
    func start(completion: ((Bool) -> Void)? = nil) {
        queue.async { [self] in
            let ok = startOnQueue()
            if let completion {
                DispatchQueue.main.async { completion(ok) }
            }
        }
    }

    private func startOnQueue() -> Bool {
        if rime.started { return true }
        guard let shared = Bundle.main.url(forResource: "RimeData", withExtension: nil) else {
            return false
        }
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let user = support.appendingPathComponent("Rime", isDirectory: true)
        try? fm.createDirectory(at: user, withIntermediateDirectories: true)
        return rime.start(withSharedDataDir: shared.path, userDataDir: user.path, schemaId: Self.schemaId)
    }

    /// 送一个键给 Rime。handled 为 false 时由调用方自己处理（比如直接插入空格、删除前一个字）。
    func process(keycode: Int32, mask: Int32 = 0,
                 completion: @escaping (_ handled: Bool, _ snapshot: RimeSnapshot) -> Void) {
        queue.async { [self] in
            _ = startOnQueue()
            let handled = rime.processKey(keycode, mask: mask)
            let snap = snapshot()
            DispatchQueue.main.async { completion(handled, snap) }
        }
    }

    /// 选第 index 个候选；revision 不匹配说明候选已过期，忽略
    func select(index: Int, revision: Int, completion: @escaping (RimeSnapshot?) -> Void) {
        queue.async { [self] in
            guard revision == self.revision else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            _ = rime.selectCandidate(at: index)
            let snap = snapshot()
            DispatchQueue.main.async { completion(snap) }
        }
    }

    func moreCandidates(from index: Int, revision: Int, completion: @escaping ([String]) -> Void) {
        queue.async { [self] in
            let list = revision == self.revision
                ? rime.candidates(fromIndex: index, limit: Self.candidateBatch)
                : []
            DispatchQueue.main.async { completion(list) }
        }
    }

    /// 把未上屏的拼音原样上屏（切英文、回车等场景）
    func commitRawInput(completion: @escaping (RimeSnapshot) -> Void) {
        queue.async { [self] in
            let raw = rime.isComposing ? rime.rawInput : ""
            rime.clearComposition()
            var snap = snapshot()
            snap.commitText = raw.isEmpty ? nil : raw
            DispatchQueue.main.async { completion(snap) }
        }
    }

    /// 上屏当前首选（输入标点前）
    func commitComposition(completion: @escaping (RimeSnapshot) -> Void) {
        queue.async { [self] in
            if rime.isComposing { _ = rime.commitComposition() }
            let snap = snapshot()
            DispatchQueue.main.async { completion(snap) }
        }
    }

    /// 清空输入（键盘收起、切换输入框时）
    func reset() {
        queue.async { [self] in
            guard rime.started else { return }
            rime.clearComposition()
            _ = rime.takeCommitText()
            revision += 1
        }
    }

    private func snapshot() -> RimeSnapshot {
        revision += 1
        var s = RimeSnapshot()
        s.revision = revision
        s.commitText = rime.takeCommitText()
        s.isComposing = rime.isComposing
        if s.isComposing {
            s.preedit = rime.preedit
            s.candidates = rime.candidates(fromIndex: 0, limit: Self.candidateBatch)
            s.mayHaveMore = s.candidates.count == Self.candidateBatch
        }
        return s
    }
}
