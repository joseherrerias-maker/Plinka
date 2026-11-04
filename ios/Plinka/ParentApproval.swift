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

// Device-only eligibility. Stop recording dates once three distinct days are reached.
enum ReviewMilestone {
    static func recordDay(_ now: Date = Date(), defaults: UserDefaults = .standard) {
        var days = defaults.stringArray(forKey: "review.days") ?? []
        guard days.count < 3 else { return }
        let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: now)
        let key = "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
        guard !days.contains(key) else { return }
        days.append(key)
        defaults.set(days, forKey: "review.days")
    }

    static func takeRequest(defaults: UserDefaults = .standard,
                            version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") -> Bool {
        guard !version.isEmpty, defaults.bool(forKey: "review.savedMusic"),
              (defaults.stringArray(forKey: "review.days") ?? []).count >= 3,
              defaults.string(forKey: "review.version") != version else { return false }
        defaults.set(version, forKey: "review.version")
        return true
    }
}
