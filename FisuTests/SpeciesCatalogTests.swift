import Testing
@testable import Fisu

@Suite struct SpeciesCatalogTests {
    @Test func lookupKnownSpecies() {
        let s = FishSpeciesCatalog.species(for: "hauki")
        #expect(s?.nameFI == "Hauki")
        #expect(s?.nameEN == "Pike")
    }

    @Test func lookupUnknownReturnsNil() {
        #expect(FishSpeciesCatalog.species(for: "unknown_fish") == nil)
    }

    @Test func otherSpeciesExists() {
        let s = FishSpeciesCatalog.species(for: "other")
        #expect(s != nil)
    }

    @Test func allSpeciesHaveUniqueCode() {
        let codes = FishSpeciesCatalog.all.map(\.code)
        #expect(codes.count == Set(codes).count)
    }
}
