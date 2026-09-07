import Foundation
import SQLite3
import SentinelCore

func assertTrue(_ condition: Bool, _ message: String = "") {
    if !condition {
        fatalError("Assertion failed. \(message)")
    }
}

print("[*] Running TCCReader & HardwareSensor Tests...")

// 1. Test Mock SQLite TCC database
let tempDBPath = "/tmp/mock_TCC.db"
if FileManager.default.fileExists(atPath: tempDBPath) {
    try? FileManager.default.removeItem(atPath: tempDBPath)
}

var db: OpaquePointer?
guard sqlite3_open(tempDBPath, &db) == SQLITE_OK else {
    fatalError("Failed to create mock TCC db")
}

let createTableSQL = """
CREATE TABLE access (
    service TEXT NOT NULL,
    client TEXT NOT NULL,
    client_type INTEGER NOT NULL,
    auth_value INTEGER NOT NULL,
    auth_reason INTEGER NOT NULL,
    auth_version INTEGER NOT NULL,
    csreq BLOB,
    policy_id INTEGER,
    indirect_object_identifier_type INTEGER,
    indirect_object_identifier TEXT,
    indirect_object_code_identity BLOB,
    flags INTEGER,
    last_modified INTEGER NOT NULL,
    pid INTEGER,
    pid_version INTEGER,
    boot_uuid TEXT,
    last_reminded INTEGER,
    prompt_count INTEGER
);
"""
sqlite3_exec(db, createTableSQL, nil, nil, nil)

// Insert sample entries
let insertSQL = """
INSERT INTO access (service, client, client_type, auth_value, auth_reason, auth_version, last_modified, prompt_count)
VALUES 
('kTCCServiceMicrophone', 'com.tinyspeck.slackmacgap', 0, 2, 1, 1, 1710000000, 1),
('kTCCServiceCamera', 'us.zoom.xos', 0, 0, 1, 1, 1710005000, 2),
('kTCCServiceScreenCapture', '/Applications/Discord.app/Contents/MacOS/Discord', 1, 2, 1, 1, 1710010000, 1);
"""
sqlite3_exec(db, insertSQL, nil, nil, nil)
sqlite3_close(db)

// Test reading mock TCC
let (entries, status) = TCCReader.readTCC(atPath: tempDBPath)
assertTrue(entries.count == 3, "Should read exactly 3 records, got \(entries.count)")

let micEntry = entries.first(where: { $0.service == "Microphone" })
assertTrue(micEntry != nil, "Microphone service entry must exist")
assertTrue(micEntry?.allowed == true, "Slack mic should be allowed")
assertTrue(micEntry?.humanReadableName == "slackmacgap", "Slack humanized name match")

let camEntry = entries.first(where: { $0.service == "Camera" })
assertTrue(camEntry?.allowed == false, "Zoom cam should be revoked (auth_value 0)")

let screenEntry = entries.first(where: { $0.service == "ScreenCapture" })
assertTrue(screenEntry?.humanReadableName == "Discord", "Discord app path should parse to binary name")

print("  - TCC SQLite parsing & permission state evaluation verified")

// 2. Test Deep Link URL generator
let url = TCCReader.privacySettingsURL(for: "Camera")
assertTrue(url?.absoluteString.contains("Privacy_Camera") == true, "Camera deep link generated correctly")
print("  - Deep link URL generation verified: \(url!.absoluteString)")

// 3. Test CoreAudio Mic query
let isMicActive = HardwareSensorWatcher.isMicrophoneActive()
print("  - HardwareSensorWatcher CoreAudio query successful (Current mic active: \(isMicActive))")

try? FileManager.default.removeItem(atPath: tempDBPath)
print("[✓] Phase 3 tests finished successfully.")
