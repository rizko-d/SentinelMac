import Foundation
#if canImport(Darwin)
import Darwin
#endif

public struct ProcessInfoResult: Equatable, Sendable {
    public let pid: pid_t
    public let name: String
    public let path: String
    public let isRunning: Bool

    public init(pid: pid_t, name: String, path: String, isRunning: Bool = true) {
        self.pid = pid
        self.name = name
        self.path = path
        self.isRunning = isRunning
    }
}

public enum ProcessResolver {
    /// Resolves executable path and process name for a given PID via Darwin libproc.
    public static func getProcessInfo(forPID pid: pid_t) -> ProcessInfoResult? {
        guard pid > 0 else { return nil }
        
        var pathBuffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        let pathLength = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
        
        if pathLength > 0 {
            let path = String(cString: pathBuffer)
            let name = (path as NSString).lastPathComponent
            return ProcessInfoResult(pid: pid, name: name.isEmpty ? "Unknown" : name, path: path, isRunning: true)
        }
        
        // Fallback to proc_name if proc_pidpath is denied or truncated
        var nameBuffer = [CChar](repeating: 0, count: 256)
        let nameLength = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
        if nameLength > 0 {
            let name = String(cString: nameBuffer)
            return ProcessInfoResult(pid: pid, name: name, path: "", isRunning: true)
        }
        
        return nil
    }
    
    /// Returns current process information
    public static func currentProcess() -> ProcessInfoResult? {
        return getProcessInfo(forPID: getpid())
    }
}
