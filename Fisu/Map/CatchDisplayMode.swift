enum CatchDisplayMode: CaseIterable {
    case dots, labels, hidden

    mutating func cycle() {
        switch self {
        case .dots:   self = .labels
        case .labels: self = .hidden
        case .hidden: self = .dots
        }
    }

    var iconName: String {
        switch self {
        case .dots:   return "eye"
        case .labels: return "eye.fill"
        case .hidden: return "eye.slash"
        }
    }
}
