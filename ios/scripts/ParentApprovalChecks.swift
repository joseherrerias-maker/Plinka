import Foundation

@main struct ParentApprovalChecks {
    static func main() {
        var gate = ParentApproval(digits: [1, 3, 5, 7])
        precondition(!gate.consume())
        precondition(gate.prompt == "one · three · five · seven")
        precondition(gate.submit("7531"))
        precondition(gate.consume())
        precondition(!gate.consume() && !gate.submit("7531"))
        var cancelled = ParentApproval(digits: [2, 4, 6, 8])
        cancelled.invalidate()
        precondition(!cancelled.submit("8642") && !cancelled.consume())
        var backgrounded = ParentApproval(digits: [2, 4, 6, 8])
        precondition(backgrounded.submit("8642"))
        backgrounded.invalidate()
        precondition(!backgrounded.consume())
        var wrong = ParentApproval(digits: [1, 3, 5, 7])
        precondition(!wrong.submit("1357") && !wrong.consume())
        precondition(!wrong.submit("") && !wrong.consume())
        let newAnswer = wrong.digits.reversed().map(String.init).joined()
        precondition(wrong.submit(newAnswer) && wrong.consume())
        print("Parent check: correct, incorrect, cancelled, invalidated and single-use approval passed.")
    }
}
