import Foundation

extension Catch {
    var lengthDisplay: String? {
        guard let mm = lengthMm else { return nil }
        return "\(mm / 10) cm"
    }

    var weightDisplay: String? {
        guard let g = weightGram else { return nil }
        if g >= 1000 {
            return String(format: "%.2f kg", Double(g) / 1000.0)
        }
        return "\(g) g"
    }

    var speciesDisplayName: String {
        if speciesCode == "other", let custom = speciesCustomName, !custom.isEmpty {
            return custom
        }
        return FishSpeciesCatalog.displayName(for: speciesCode)
    }

    var sizeDisplay: String {
        [lengthDisplay, weightDisplay].compactMap { $0 }.joined(separator: " · ")
    }
}

extension DateFormatter {
    static let fiShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d.M."
        f.locale = Locale(identifier: "fi_FI")
        return f
    }()

    static let fiDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d.M.yyyy HH:mm"
        f.locale = Locale(identifier: "fi_FI")
        return f
    }()
}
