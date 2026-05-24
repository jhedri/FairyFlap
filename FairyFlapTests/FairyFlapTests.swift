import Testing

@Suite("FairyFlap basic tests")
struct FairyFlapTests {
    @Test("Sanity check")
    func sanityCheck() {
        #expect(1 + 1 == 2)
    }

    @Test("Score label string formats correctly")
    func scoreStringFormats() {
        let score = 7
        #expect(String(score) == "7")
    }
}
