import Foundation

@main struct ParentApprovalChecks {
    static func main() {
        let suite = UUID().uuidString
        let prefs = UserDefaults(suiteName: suite)!
        defer { prefs.removePersistentDomain(forName: suite) }
        let today = Date()
        for offset in [0, 0, 1] {
            ReviewMilestone.recordDay(today.addingTimeInterval(Double(offset) * 86400), defaults: prefs)
        }
        prefs.set(true, forKey: "review.savedMusic")
        precondition(!ReviewMilestone.takeRequest(defaults: prefs, version: "1.1"))
        ReviewMilestone.recordDay(today.addingTimeInterval(172800), defaults: prefs)
        prefs.set(false, forKey: "review.savedMusic")
        precondition(!ReviewMilestone.takeRequest(defaults: prefs, version: "1.1"))
        prefs.set(true, forKey: "review.savedMusic")
        precondition(ReviewMilestone.takeRequest(defaults: prefs, version: "1.1"))
        precondition(!ReviewMilestone.takeRequest(defaults: prefs, version: "1.1"))
        var gate = ParentApproval(digits: [1, 3, 5, 7])
        precondition(!gate.consume())
        precondition(gate.prompt == "one · three · five · seven")
        precondition(gate.submit("1357"))
        precondition(gate.consume())
        precondition(!gate.consume() && !gate.submit("1357"))
        var cancelled = ParentApproval(digits: [2, 4, 6, 8])
        cancelled.invalidate()
        precondition(!cancelled.submit("2468") && !cancelled.consume())
        var backgrounded = ParentApproval(digits: [2, 4, 6, 8])
        precondition(backgrounded.submit("2468"))
        backgrounded.invalidate()
        precondition(!backgrounded.consume())
        var wrong = ParentApproval(digits: [1, 3, 5, 7])
        precondition(!wrong.submit("7531") && !wrong.consume())
        precondition(!wrong.submit("") && !wrong.consume())
        let newAnswer = wrong.digits.map(String.init).joined()
        precondition(wrong.submit(newAnswer) && wrong.consume())
        print("Parent check: correct, incorrect, cancelled, invalidated and single-use approval passed.")
    }
}
