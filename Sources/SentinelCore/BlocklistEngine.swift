import Foundation

public final class BlocklistEngine: @unchecked Sendable {
    private let lock = NSLock()
    private var blockedDomains: Set<String> = []

    public init(domains: [String] = []) {
        self.blockedDomains = Set(domains.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
    }

    public func load(fromFilePath path: String) {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        load(fromString: content)
    }

    public func load(fromString content: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            blockedDomains.insert(trimmed)
        }
    }

    public func isBlocked(domain: String) -> Bool {
        let clean = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty { return false }
        
        lock.lock()
        defer { lock.unlock() }

        // Exact match
        if blockedDomains.contains(clean) { return true }

        // Subdomain match (e.g., test.google-analytics.com matches google-analytics.com)
        let parts = clean.split(separator: ".")
        if parts.count > 2 {
            for i in 1..<(parts.count - 1) {
                let suffix = parts[i...].joined(separator: ".")
                if blockedDomains.contains(suffix) {
                    return true
                }
            }
        }
        return false
    }

    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return blockedDomains.count
    }
}
