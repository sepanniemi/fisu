import SwiftUI

struct FishSpecies: Identifiable, Sendable {
    let code: String
    let nameFI: String
    let nameEN: String
    let color: Color
    var id: String { code }
}

enum FishSpeciesCatalog {
    // Species codes are ASCII-only (e.g. "sarki" not "särki") for safe use as DB keys.
    private static let fallbackColor = Color(red: 0.54, green: 0.54, blue: 0.54)

    static let all: [FishSpecies] = [
        FishSpecies(code: "ahven",     nameFI: "Ahven",     nameEN: "Perch",         color: Color(red: 0.88, green: 0.64, blue: 0.23)),
        FishSpecies(code: "hauki",     nameFI: "Hauki",     nameEN: "Pike",          color: Color(red: 0.18, green: 0.55, blue: 0.34)),
        FishSpecies(code: "kuha",      nameFI: "Kuha",      nameEN: "Zander",        color: Color(red: 0.36, green: 0.51, blue: 0.68)),
        FishSpecies(code: "taimen",    nameFI: "Taimen",    nameEN: "Brown trout",   color: Color(red: 0.71, green: 0.40, blue: 0.11)),
        FishSpecies(code: "kirjolohi", nameFI: "Kirjolohi", nameEN: "Rainbow trout", color: Color(red: 0.81, green: 0.42, blue: 0.48)),
        FishSpecies(code: "lohi",      nameFI: "Lohi",      nameEN: "Salmon",        color: Color(red: 0.85, green: 0.54, blue: 0.24)),
        FishSpecies(code: "siika",     nameFI: "Siika",     nameEN: "Whitefish",     color: Color(red: 0.72, green: 0.72, blue: 0.72)),
        FishSpecies(code: "made",      nameFI: "Made",      nameEN: "Burbot",        color: Color(red: 0.49, green: 0.42, blue: 0.33)),
        FishSpecies(code: "lahna",     nameFI: "Lahna",     nameEN: "Bream",         color: Color(red: 0.60, green: 0.56, blue: 0.36)),
        FishSpecies(code: "sarki",     nameFI: "Särki",     nameEN: "Roach",         color: Color(red: 0.76, green: 0.30, blue: 0.30)),
        FishSpecies(code: "niera",     nameFI: "Nieriä",    nameEN: "Arctic char",   color: Color(red: 0.90, green: 0.45, blue: 0.20)),
        FishSpecies(code: "harjus",    nameFI: "Harjus",    nameEN: "Grayling",      color: Color(red: 0.42, green: 0.35, blue: 0.60)),
        FishSpecies(code: "sayne",     nameFI: "Säyne",     nameEN: "Ide",           color: Color(red: 0.50, green: 0.60, blue: 0.40)),
        FishSpecies(code: "kuore",     nameFI: "Kuore",     nameEN: "Smelt",         color: Color(red: 0.65, green: 0.75, blue: 0.85)),
        FishSpecies(code: "other",     nameFI: "Muu",       nameEN: "Other",         color: Color(red: 0.54, green: 0.54, blue: 0.54)),
    ]

    static func species(for code: String) -> FishSpecies? {
        all.first { $0.code == code }
    }

    static func color(for code: String?) -> Color {
        guard let code else { return fallbackColor }
        return species(for: code)?.color ?? fallbackColor
    }

    static func displayName(for code: String?) -> String {
        guard let code else { return "–" }
        return species(for: code)?.nameFI ?? "–"
    }
}
