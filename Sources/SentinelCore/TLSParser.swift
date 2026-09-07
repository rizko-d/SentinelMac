import Foundation

public enum TLSParser {
    /// Extracts Server Name Indication (SNI) from raw TLS ClientHello bytes without decryption.
    /// Standard: RFC 6066 Section 3 (Server Name Indication)
    public static func extractSNI(from data: Data) -> String? {
        guard data.count > 5 else { return nil }
        let bytes = [UInt8](data)
        
        // Byte 0: ContentType (0x16 = Handshake)
        // Byte 1-2: Protocol Version (0x03, 0x01 / 0x02 / 0x03)
        guard bytes[0] == 0x16 && bytes[1] == 0x03 else { return nil }
        
        var index = 5 // Skip TLS Record Header (Type: 1, Version: 2, Length: 2)
        guard index < bytes.count, bytes[index] == 0x01 else { return nil } // Handshake Type 0x01 = ClientHello
        
        // Skip ClientHello Header:
        // Handshake type: 1 byte
        // Length: 3 bytes
        // Client Version: 2 bytes
        // Random: 32 bytes
        // Total offset = 1 + 3 + 2 + 32 = 38 bytes
        index += 38
        guard index < bytes.count else { return nil }
        
        // Session ID length
        let sessionIdLength = Int(bytes[index])
        index += 1 + sessionIdLength
        guard index + 1 < bytes.count else { return nil }
        
        // Cipher Suites length
        let cipherSuiteLength = (Int(bytes[index]) << 8) | Int(bytes[index + 1])
        index += 2 + cipherSuiteLength
        guard index < bytes.count else { return nil }
        
        // Compression Methods length
        let compressionMethodsLength = Int(bytes[index])
        index += 1 + compressionMethodsLength
        guard index + 1 < bytes.count else { return nil }
        
        // Extensions length
        let extensionsLength = (Int(bytes[index]) << 8) | Int(bytes[index + 1])
        index += 2
        let extensionsEnd = min(index + extensionsLength, bytes.count)
        
        // Iterate extensions
        while index + 4 <= extensionsEnd {
            let extType = (Int(bytes[index]) << 8) | Int(bytes[index + 1])
            let extLen = (Int(bytes[index + 2]) << 8) | Int(bytes[index + 3])
            index += 4
            
            // Extension 0x0000 = server_name (SNI)
            if extType == 0x0000 {
                var sniIndex = index + 2 // Skip server_name_list length (2 bytes)
                guard sniIndex + 3 <= bytes.count else { return nil }
                
                let nameType = bytes[sniIndex] // 0 = host_name
                if nameType == 0 {
                    let nameLength = (Int(bytes[sniIndex + 1]) << 8) | Int(bytes[sniIndex + 2])
                    sniIndex += 3
                    guard sniIndex + nameLength <= bytes.count else { return nil }
                    let hostBytes = bytes[sniIndex..<(sniIndex + nameLength)]
                    return String(bytes: hostBytes, encoding: .utf8)
                }
            }
            index += extLen
        }
        return nil
    }
}
