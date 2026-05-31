import MapKit
import UIKit

final class ClusterAnnotationView: MKAnnotationView {
    private let countLabel = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
        layer.cornerRadius = 17
        backgroundColor = UIColor(red: 0.09, green: 0.42, blue: 0.23, alpha: 1)
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2.5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 3

        countLabel.textColor = .white
        countLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var annotation: MKAnnotation? {
        didSet {
            if let cluster = annotation as? MKClusterAnnotation {
                countLabel.text = "\(cluster.memberAnnotations.count)"
            }
        }
    }
}
