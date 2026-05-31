import Foundation

struct CatchFilter {
    enum SortOrder { case newestFirst, biggestFirst }

    var species: Set<String>? = nil
    var dateRange: ClosedRange<Date>? = nil
    var sortOrder: SortOrder = .newestFirst

    static let `default` = CatchFilter()

    func apply(to catches: [Catch]) -> [Catch] {
        var result = catches

        if let species, !species.isEmpty {
            result = result.filter {
                guard let code = $0.speciesCode else { return false }
                return species.contains(code)
            }
        }

        if let range = dateRange {
            result = result.filter { range.contains($0.timestamp) }
        }

        switch sortOrder {
        case .newestFirst:
            result.sort { $0.timestamp > $1.timestamp }
        case .biggestFirst:
            result.sort { Self.isBigger($0, than: $1) }
        }

        return result
    }

    static func isBigger(_ a: Catch, than b: Catch) -> Bool {
        switch (a.weightGram, b.weightGram) {
        case let (aw?, bw?): return aw > bw
        case (_?, nil):      return true
        case (nil, _?):      return false
        default:
            switch (a.lengthMm, b.lengthMm) {
            case let (al?, bl?): return al > bl
            default:             return false
            }
        }
    }
}
