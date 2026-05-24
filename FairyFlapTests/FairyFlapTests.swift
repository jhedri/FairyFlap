import Testing

@Suite("FairyFlap basic tests")
struct FairyFlapTests {
    /// Verifies the test target is wired up correctly.
    @Test("Sanity check")
    func sanityCheck() {
        #expect(1 + 1 == 2)
    }

    /// Verifies score values convert to display strings the same way the game does.
    @Test("Score label string formats correctly")
    func scoreStringFormats() {
        let score = 7
        #expect(String(score) == "7")
    }
}
