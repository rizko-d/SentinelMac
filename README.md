# macOS Privacy Sentinel (SentinelMac)

**SentinelMac** is a lightweight, native macOS privacy utility and system security auditor engineered for macOS 14+ (Sonoma & Sequoia). Built with modern Swift, SwiftUI, and Darwin kernel APIs, SentinelMac bridges the gap between Apple's built-in privacy indicators and deep, actionable process attribution.

Developed as a flagship **Cybersecurity & Privacy Track** portfolio project for the **Apple Developer Academy**.

---

## 🎯 The Core Problem & Philosophy

macOS provides visual privacy indicators (like the orange/green dots in the Menu Bar when microphone/camera are active). However, for everyday users and security researchers alike, critical questions remain unanswered:
1. **Who?** Which background process or subprocess actually initiated the sensor/network stream?
2. **Where?** To which third-party tracking endpoint or telemetry domain is data outbound?
3. **Actionability?** How does a user immediately understand and remediate background data leakage without breaking TLS certificates or decrypting private data?

SentinelMac adheres strictly to the philosophy: **"Privacy is a fundamental human right, and security tools should not destroy privacy to monitor it."**

---

## ⚡ Key Technical Highlights

- **Zero-Decryption SNI Inspection:** Parses raw TLS `ClientHello` packets via binary frame analysis to extract Server Name Indication (SNI) hostnames without installing root certificates, SSL bumping, or MITM decryption.
- **Darwin Kernel Process Attribution (`libproc`):** Direct POSIX & C-bridging to Darwin system APIs (`proc_pidpath`, `proc_pidinfo`) mapping connection sockets and PIDs to real disk binaries.
- **TCC (Transparency, Consent, and Control) Auditor:** Read-only SQLite auditor inspects macOS `TCC.db` records to report persistent permissions (Camera, Microphone, Screen Recording, Full Disk Access) with deep-links to native macOS System Settings.
- **Hardware Sensor Activity Watcher:** CoreAudio hardware property listener (`AudioObjectAddPropertyListener`) alerting in real-time when the default audio input stream transitions to active.
- **Human-Centered Apple HIG Experience:** SwiftUI Menu Bar extra with quick telemetry toggles, combined with a clean detached Dashboard window presenting humanized risk summaries instead of raw undecipherable security logs.

---

## 🏗️ Architecture

```
SentinelMac/
├── Sources/
│   ├── SentinelMac/                 # CLI & Service Runner / Entry Point
│   ├── SentinelCore/                # Native Security & Networking Engine
│   │   ├── ProcessResolver.swift    # libproc C-bridge PID & binary attribution
│   │   ├── TLSParser.swift          # Zero-decryption TLS ClientHello SNI extractor
│   │   ├── LocalProxyServer.swift   # NWListener / Loopback HTTP CONNECT proxy
│   │   ├── BlocklistEngine.swift    # Tracker & telemetry domain matching engine
│   │   ├── TCCReader.swift          # Read-only SQLite TCC.db permission auditor
│   │   └── HardwareSensorWatcher.swift # CoreAudio hardware listener
│   └── CProcBridge/                 # C-module bridging libproc & kernel headers
├── Resources/
│   └── blocklists/                  # Curated tracker & telemetry radar rules
└── Docs/
    ├── CBL_CASE_STUDY.md            # Challenge Based Learning (CBL) Case Study
    └── ARCHITECTURE_DEEP_DIVE.md    # Low-level engineering documentation
```

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.0+ (Sonoma / Sequoia)
- Swift 5.10 / Swift 6 toolchain (Xcode 15+ or CommandLineTools)

### Build & Run
```bash
# Clone the repository
git clone https://github.com/rizko-d/SentinelMac.git
cd SentinelMac

# Build with Swift Package Manager
swift build -c release

# Run tests
swift test
```

---

## 🛡️ Privacy & Security Design Notes

1. **No MITM / No Root Certs:** SentinelMac never installs or trusts custom Root CAs. HTTPS payloads remain 100% end-to-end encrypted.
2. **Read-Only SQLite Operations:** `TCC.db` is queried using `SQLITE_OPEN_READONLY` to eliminate any risk of database tampering or corruption.
3. **Local-Only:** SentinelMac performs zero telemetry of its own. All logs, buffer events, and audit states exist purely in local memory.

---

## 📜 License & Acknowledgments

Distributed under the MIT License. Developed by [Rizko F Rachmayadi](https://github.com/rizko-d).
