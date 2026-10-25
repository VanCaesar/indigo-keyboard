import UIKit

protocol CandidateBarDelegate: AnyObject {
    func candidateBar(_ bar: CandidateBar, didSelect index: Int)
    func candidateBar(_ bar: CandidateBar, didTapSymbol symbol: String)
    func candidateBarNeedsMore(_ bar: CandidateBar)
}

/// 候选栏：打字时上方一行小字显示拼音，下方横向滚动候选（首选靛蓝）；
/// 不打字时显示常用标点，和系统键盘一样。
final class CandidateBar: UIView {
    static let height: CGFloat = 48

    weak var delegate: CandidateBarDelegate?

    private let preeditLabel = UILabel()
    private let collection: UICollectionView
    private var candidates: [String] = []
    private var widths: [CGFloat] = []

    /// 不打字时显示的标点
    var quickSymbols: [String] = [] {
        didSet { if showingSymbols, quickSymbols != oldValue { reload() } }
    }
    private var showingSymbols: Bool { candidates.isEmpty && (preeditLabel.text ?? "").isEmpty }
    private var items: [String] { showingSymbols ? quickSymbols : candidates }

    private static let font = UIFont.systemFont(ofSize: 20)
    private static let firstFont = UIFont.systemFont(ofSize: 20, weight: .medium)
    private static let cellPadding: CGFloat = 12

    var theme: Theme = .light {
        didSet {
            guard theme != oldValue else { return }
            applyTheme()
            collection.reloadData()
        }
    }

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        backgroundColor = .clear

        preeditLabel.font = .systemFont(ofSize: 13)
        addSubview(preeditLabel)

        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceHorizontal = true
        collection.delaysContentTouches = false
        collection.contentInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        collection.register(CandidateCell.self, forCellWithReuseIdentifier: CandidateCell.id)
        collection.dataSource = self
        collection.delegate = self
        addSubview(collection)

        applyTheme()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        preeditLabel.frame = CGRect(x: 12, y: 2, width: bounds.width - 24, height: 16)
        collection.frame = CGRect(x: 0, y: 16, width: bounds.width, height: bounds.height - 16)
    }

    func update(preedit: String, candidates: [String]) {
        preeditLabel.text = preedit
        self.candidates = candidates
        reload()
    }

    func append(_ more: [String]) {
        guard !more.isEmpty, !showingSymbols else { return }
        let start = candidates.count
        candidates += more
        widths += more.map { Self.width(of: $0, first: false) }
        let paths = (start..<candidates.count).map { IndexPath(item: $0, section: 0) }
        UIView.performWithoutAnimation {
            collection.insertItems(at: paths)
        }
    }

    private func reload() {
        widths = showingSymbols
            ? quickSymbols.map { max(40, Self.width(of: $0, first: false) - 8) }
            : candidates.enumerated().map { Self.width(of: $1, first: $0 == 0) }
        collection.reloadData()
        collection.setContentOffset(CGPoint(x: -collection.contentInset.left, y: 0), animated: false)
    }

    private static func width(of text: String, first: Bool) -> CGFloat {
        let w = (text as NSString).size(withAttributes: [.font: first ? firstFont : font]).width
        return ceil(max(w, 14)) + cellPadding * 2
    }

    private func applyTheme() {
        preeditLabel.textColor = theme.secondaryText
    }
}

extension CandidateBar: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandidateCell.id, for: indexPath) as! CandidateCell
        let first = indexPath.item == 0 && !showingSymbols
        cell.configure(text: items[indexPath.item],
                       font: first ? Self.firstFont : Self.font,
                       color: first ? theme.indigo : theme.keyText,
                       highlight: theme.keyText.withAlphaComponent(0.08))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: widths[indexPath.item], height: collectionView.bounds.height)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if !showingSymbols, indexPath.item >= candidates.count - 10 {
            delegate?.candidateBarNeedsMore(self)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if showingSymbols {
            delegate?.candidateBar(self, didTapSymbol: quickSymbols[indexPath.item])
        } else {
            delegate?.candidateBar(self, didSelect: indexPath.item)
        }
    }
}

final class CandidateCell: UICollectionViewCell {
    static let id = "CandidateCell"
    private let label = UILabel()
    private var highlightColor: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        contentView.addSubview(label)
        contentView.layer.cornerRadius = 8
        contentView.layer.cornerCurve = .continuous
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }

    override var isHighlighted: Bool {
        didSet { contentView.backgroundColor = isHighlighted ? highlightColor : .clear }
    }

    func configure(text: String, font: UIFont, color: UIColor, highlight: UIColor) {
        label.text = text
        label.font = font
        label.textColor = color
        highlightColor = highlight
    }
}
