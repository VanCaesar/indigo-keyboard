import UIKit

protocol CandidateBarDelegate: AnyObject {
    func candidateBar(_ bar: CandidateBar, didSelect index: Int)
    func candidateBarNeedsMore(_ bar: CandidateBar)
    func candidateBarDismissKeyboard(_ bar: CandidateBar)
}

/// 候选栏：上方一行小字显示拼音，下方横向滚动候选；首选用靛蓝。
final class CandidateBar: UIView {
    static let height: CGFloat = 48

    weak var delegate: CandidateBarDelegate?

    private let preeditLabel = UILabel()
    private let dismissButton = UIButton(type: .system)
    private let collection: UICollectionView
    private var candidates: [String] = []
    private var widths: [CGFloat] = []

    private static let font = UIFont.systemFont(ofSize: 19)
    private static let firstFont = UIFont.systemFont(ofSize: 19, weight: .medium)
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

        preeditLabel.font = .systemFont(ofSize: 13)
        addSubview(preeditLabel)

        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceHorizontal = true
        collection.delaysContentTouches = false
        collection.register(CandidateCell.self, forCellWithReuseIdentifier: CandidateCell.id)
        collection.dataSource = self
        collection.delegate = self
        addSubview(collection)

        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        dismissButton.setImage(UIImage(systemName: "keyboard.chevron.compact.down", withConfiguration: config),
                               for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        addSubview(dismissButton)

        applyTheme()
        update(preedit: "", candidates: [])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        preeditLabel.frame = CGRect(x: 10, y: 2, width: bounds.width - 20, height: 16)
        collection.frame = CGRect(x: 0, y: 16, width: bounds.width, height: bounds.height - 16)
        dismissButton.frame = CGRect(x: bounds.width - 50, y: 0, width: 50, height: bounds.height)
    }

    func update(preedit: String, candidates: [String]) {
        preeditLabel.text = preedit
        self.candidates = candidates
        widths = candidates.enumerated().map { Self.width(of: $1, first: $0 == 0) }
        dismissButton.isHidden = !candidates.isEmpty || !preedit.isEmpty
        collection.reloadData()
        collection.setContentOffset(.zero, animated: false)
    }

    func append(_ more: [String]) {
        guard !more.isEmpty else { return }
        let start = candidates.count
        candidates += more
        widths += more.map { Self.width(of: $0, first: false) }
        let paths = (start..<candidates.count).map { IndexPath(item: $0, section: 0) }
        UIView.performWithoutAnimation {
            collection.insertItems(at: paths)
        }
    }

    private static func width(of text: String, first: Bool) -> CGFloat {
        let w = (text as NSString).size(withAttributes: [.font: first ? firstFont : font]).width
        return ceil(max(w, 14)) + cellPadding * 2
    }

    private func applyTheme() {
        backgroundColor = theme.background
        preeditLabel.textColor = theme.secondaryText
        dismissButton.tintColor = theme.secondaryText
    }

    @objc private func dismissTapped() {
        delegate?.candidateBarDismissKeyboard(self)
    }
}

extension CandidateBar: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        candidates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandidateCell.id, for: indexPath) as! CandidateCell
        let first = indexPath.item == 0
        cell.configure(text: candidates[indexPath.item],
                       font: first ? Self.firstFont : Self.font,
                       color: first ? theme.indigo : theme.keyText,
                       highlight: theme.functionKey.withAlphaComponent(0.5))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: widths[indexPath.item], height: collectionView.bounds.height)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if indexPath.item >= candidates.count - 10 {
            delegate?.candidateBarNeedsMore(self)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        delegate?.candidateBar(self, didSelect: indexPath.item)
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
        contentView.layer.cornerRadius = 6
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
