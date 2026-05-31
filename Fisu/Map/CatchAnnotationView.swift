import MapKit
import UIKit

final class CatchAnnotationView: MKAnnotationView {
    static let reuseId = "CatchAnnotationView"

    var displayMode: CatchDisplayMode = .dots {
        didSet { updateAppearance() }
    }

    private var label: UILabel?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "catches"
        canShowCallout = false
        bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        layer.cornerRadius = 7
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 0, height: 1)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        label?.removeFromSuperview()
        label = nil
    }

    override var annotation: MKAnnotation? {
        didSet { updateAppearance() }
    }

    private func updateAppearance() {
        guard let catchAnnotation = annotation as? CatchAnnotation else { return }
        let species = catchAnnotation.entry.speciesCode
        let uiColor = UIColor(FishSpeciesCatalog.color(for: species))
        backgroundColor = uiColor

        label?.removeFromSuperview()
        label = nil

        if displayMode == .labels {
            let lbl = UILabel()
            lbl.font = .systemFont(ofSize: 9, weight: .bold)
            lbl.textColor = .label
            lbl.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
            lbl.layer.cornerRadius = 4
            lbl.clipsToBounds = true
            let name = FishSpeciesCatalog.displayName(for: species)
            let dateStr = DateFormatter.fiShort.string(from: catchAnnotation.entry.timestamp)
            lbl.text = " \(name) \(dateStr) "
            lbl.sizeToFit()
            lbl.frame.origin = CGPoint(x: 16, y: -lbl.frame.height / 2 + 7)
            addSubview(lbl)
            label = lbl
        }
    }
}
