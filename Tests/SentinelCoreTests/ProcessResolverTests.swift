import Foundation
import SentinelCore

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "") {
    if a != b {
        fatalError("Assertion failed: \(a) != \(b). \(message)")
    }
}

func assertTrue(_ condition: Bool, _ message: String = "") {
    if !condition {
        fatalError("Assertion failed. \(message)")
    }
}

print("[*] Running ProcessResolver Tests...")

let current = ProcessResolver.currentProcess()
assertTrue(current != nil, "Current process must be resolvable")
assertTrue((current?.pid ?? 0) > 0, "PID must be positive")
assertTrue(!(current?.name.isEmpty ?? true), "Process name must not be empty")
print("  - Current Process: \(current!.name) (PID: \(current!.pid))")

let invalid = ProcessResolver.getProcessInfo(forPID: -1)
assertTrue(invalid == nil, "Invalid PID -1 should return nil")
print("  - Invalid PID rejection verified")

print("[✓] ProcessResolver unit tests finished successfully.")
