import Testing
@testable import Fisu

@Suite struct FormattingTests {
    @Test func lengthDisplay() {
        let c = Catch(); c.lengthMm = 780
        #expect(c.lengthDisplay == "78 cm")
    }

    @Test func lengthNilWhenUnset() {
        let c = Catch()
        #expect(c.lengthDisplay == nil)
    }

    @Test func weightKgAboveThreshold() {
        let c = Catch(); c.weightGram = 3400
        #expect(c.weightDisplay == "3.40 kg")
    }

    @Test func weightGramBelowThreshold() {
        let c = Catch(); c.weightGram = 240
        #expect(c.weightDisplay == "240 g")
    }

    @Test func weightExactKg() {
        let c = Catch(); c.weightGram = 1000
        #expect(c.weightDisplay == "1.00 kg")
    }

    @Test func weightNilWhenUnset() {
        let c = Catch()
        #expect(c.weightDisplay == nil)
    }
}
