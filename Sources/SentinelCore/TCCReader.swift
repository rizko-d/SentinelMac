import Foundation
import SQLite3

public struct TCCPermissionEntry: Identifiable, Sendable {
    public let id = UUID()
    public let service: String
    public let client: String
    public let allowed: Bool
    public let promptCount: Int
    public let lastModified: Date
    public let humanReadableName: String

    public init(service: String, client: String, allowed: Bool, promptCount: Int = 0, lastModified: Date = Date()) {
        self.service = service
        self.client = client
        self.allowed = allowed
        self.promptCount = promptCount
        self.lastModified = lastModified
        
        // Humanized app name translation
        if client.contains("/") {
            self.humanReadableName = (client as NSString).lastPathComponent
        } else {
            let parts = client.split(separator: ".")
            self.humanReadableName = parts.last.map(String.init) ?? client
        }
    }
}

public enum TCCAuditStatus: Sendable {
    case fullDiskAccessGranted
    case fullDiskAccessRequired
    case databaseNotFound
    case error(String)
}

public final class TCCReader: @unchecked Sendable {
    public static let userTCCPath = ("~/Library/Application Support/com.apple.TCC/TCC.db" as NSString).expandingTildeInPath
    public static let systemTCCPath = "/Library/Application Support/com.apple.TCC/TCC.db"

    public static func checkStatus(atPath path: String = userTCCPath) -> TCCAuditStatus {
        guard FileManager.default.fileExists(atPath: path) else {
            return .databaseNotFound
        }

        var db: OpaquePointer?
        let result = sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil)
        if result == SQLITE_OK {
            sqlite3_close(db)
            return .fullDiskAccessGranted
        } else {
            return .fullDiskAccessRequired
        }
    }

    /// Reads TCC records from target SQLite database (defaults to User domain)
    public static func readTCC(atPath path: String = userTCCPath) -> (entries: [TCCPermissionEntry], status: TCCAuditStatus) {
        guard FileManager.default.fileExists(atPath: path) else {
            return ([], .databaseNotFound)
        }

        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return ([], .fullDiskAccessRequired)
        }
        defer { sqlite3_close(db) }

        let query = "SELECT service, client, auth_value, prompt_count, last_modified FROM access"
        var stmt: OpaquePointer?
        var entries: [TCCPermissionEntry] = []

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let service = String(cString: sqlite3_column_text(stmt, 0))
                let client = String(cString: sqlite3_column_text(stmt, 1))
                let authValue = sqlite3_column_int(stmt, 2)
                let promptCount = Int(sqlite3_column_int(stmt, 3))
                let lastMod = sqlite3_column_int64(stmt, 4)

                let cleanService = service.replacingOccurrences(of: "kTCCService", with: "")
                // auth_value: 2 = Allowed, 0 = Denied / Revoked
                let allowed = (authValue == 2)
                let modDate = lastMod > 0 ? Date(timeIntervalSince1970: TimeInterval(lastMod)) : Date()

                entries.append(TCCPermissionEntry(
                    service: cleanService,
                    client: client,
                    allowed: allowed,
                    promptCount: promptCount,
                    lastModified: modDate
                ))
            }
        } else {
            let errMsg = String(cString: sqlite3_errmsg(db))
            return ([], .error(errMsg))
        }
        sqlite3_finalize(stmt)
        return (entries, .fullDiskAccessGranted)
    }

    /// Deep link helper to open macOS Settings directly at the target privacy pane
    public static func privacySettingsURL(for service: String) -> URL? {
        let prefix = "x-apple.systempreferences:com.apple.preference.security?Privacy_"
        switch service.lowercased() {
        case "camera":
            return URL(string: prefix + "Camera")
        case "microphone":
            return URL(string: prefix + "Microphone")
        case "screencapture", "screenrecording":
            return URL(string: prefix + "ScreenCapture")
        case "systempolicyallevents", "accessibility":
            return URL(string: prefix + "Accessibility")
        case "systempolicyfulldisk", "fulldisk":
            return URL(string: prefix + "AllFiles")
        default:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security")
        }
    }
}
