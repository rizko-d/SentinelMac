import Foundation
import SentinelCore

print("=== SentinelMac Security Engine Initialized ===")
if let proc = ProcessResolver.currentProcess() {
    print("Self PID: \(proc.pid)")
    print("Self Binary: \(proc.name)")
    print("Self Path: \(proc.path)")
}
