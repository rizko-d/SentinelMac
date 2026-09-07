import Foundation
import SentinelCore

func assertTrue(_ condition: Bool, _ message: String = "") {
    if !condition {
        fatalError("Assertion failed. \(message)")
    }
}

print("[*] Running TLSParser & Blocklist Tests...")

// 1. Test Blocklist exact and subdomain
let blocklist = BlocklistEngine()
blocklist.load(fromString: """
# Comments should be skipped
google-analytics.com
graph.facebook.com
doubleclick.net
""")

assertTrue(blocklist.isBlocked(domain: "google-analytics.com"), "Exact domain should be blocked")
assertTrue(blocklist.isBlocked(domain: "ssl.google-analytics.com"), "Subdomain should be blocked")
assertTrue(blocklist.isBlocked(domain: "GRAPH.FACEBOOK.COM"), "Case insensitive match should pass")
assertTrue(!blocklist.isBlocked(domain: "apple.com"), "Clean domain should not be blocked")
assertTrue(!blocklist.isBlocked(domain: "notgoogle-analytics.com"), "Partial string mismatch should not match")
print("  - Blocklist exact & subdomain matching verified")

// 2. Synthesize a mock TLS ClientHello with SNI = "apple.com"
var packet = [UInt8]()
// TLS Record Header: Handshake (0x16), Version (0x03, 0x01)
packet.append(contentsOf: [0x16, 0x03, 0x01, 0x00, 0x00]) // length placeholder
let recordHeaderLen = packet.count

// ClientHello Header: Type=1 (ClientHello), Length=3 bytes placeholder
packet.append(contentsOf: [0x01, 0x00, 0x00, 0x00])
let clientHelloStart = packet.count

// Version (TLS 1.2 = 0x03, 0x03)
packet.append(contentsOf: [0x03, 0x03])

// Random (32 bytes)
packet.append(contentsOf: [UInt8](repeating: 0x42, count: 32))

// Session ID length (0)
packet.append(0x00)

// Cipher Suites (2 bytes length = 2, 2 bytes cipher = 0xc0, 0x2f)
packet.append(contentsOf: [0x00, 0x02, 0xc0, 0x2f])

// Compression methods (1 byte len = 1, method = 0x00)
packet.append(contentsOf: [0x01, 0x00])

// Extensions length placeholder (2 bytes)
let extLenPos = packet.count
packet.append(contentsOf: [0x00, 0x00])

// Extension: server_name (Type = 0x0000, Length = ?)
let sniExtStart = packet.count
packet.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Type 0x0000, Length placeholder

let serverNameListStart = packet.count
packet.append(contentsOf: [0x00, 0x00]) // server_name_list length placeholder

// Host entry: name_type = 0 (host_name)
packet.append(0x00)
let host = "apple.com"
let hostBytes = [UInt8](host.utf8)
packet.append(contentsOf: [UInt8(hostBytes.count >> 8), UInt8(hostBytes.count & 0xFF)])
packet.append(contentsOf: hostBytes)

// Backfill server_name_list length
let listLen = packet.count - (serverNameListStart + 2)
packet[serverNameListStart] = UInt8(listLen >> 8)
packet[serverNameListStart + 1] = UInt8(listLen & 0xFF)

// Backfill SNI extension length
let extContentLen = packet.count - (sniExtStart + 4)
packet[sniExtStart + 2] = UInt8(extContentLen >> 8)
packet[sniExtStart + 3] = UInt8(extContentLen & 0xFF)

// Backfill Total Extensions length
let totalExtLen = packet.count - (extLenPos + 2)
packet[extLenPos] = UInt8(totalExtLen >> 8)
packet[extLenPos + 1] = UInt8(totalExtLen & 0xFF)

// Backfill ClientHello length
let clientHelloLen = packet.count - clientHelloStart
packet[clientHelloStart - 3] = UInt8((clientHelloLen >> 16) & 0xFF)
packet[clientHelloStart - 2] = UInt8((clientHelloLen >> 8) & 0xFF)
packet[clientHelloStart - 1] = UInt8(clientHelloLen & 0xFF)

// Backfill Record length
let recordLen = packet.count - recordHeaderLen
packet[3] = UInt8((recordLen >> 8) & 0xFF)
packet[4] = UInt8(recordLen & 0xFF)

let data = Data(packet)
let parsedSNI = TLSParser.extractSNI(from: data)
assertTrue(parsedSNI == "apple.com", "Extracted SNI must be 'apple.com', got '\(parsedSNI ?? "nil")'")
print("  - Zero-decryption TLS ClientHello SNI extracted: \(parsedSNI!)")

print("[✓] Phase 2 tests finished successfully.")
