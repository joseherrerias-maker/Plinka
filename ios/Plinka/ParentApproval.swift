import Foundation

/// Reading challenge for a parent action, not identity or age verification.
struct ParentApproval {
    private(set) var digits: [Int]
    private var approved = false
    private var active = true
    private static let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]

    init(digits: [Int] = Array((1...9).shuffled().prefix(4))) {
        precondition(digits.count == 4 && digits.allSatisfy { (0...9).contains($0) })
        self.digits = digits
    }
    var prompt: String { digits.map { Self.words[$0] }.joined(separator: " · ") }
    mutating func submit(_ answer: String) -> Bool {
        guard active else { return false }
        approved = answer == digits.map(String.init).joined()
        if !approved { digits = Array((1...9).shuffled().prefix(4)) }
        return approved
    }
    mutating func consume() -> Bool {
        guard active && approved else { return false }
        invalidate()
        return true
    }
    mutating func invalidate() { active = false; approved = false }
}
