import Foundation
import Observation

@Observable
public final class AppState: @unchecked Sendable {
    public var networkEvents: [NetworkEvent] = []
    public var tccEntries: [TCCPermissionEntry] = []
    public var isProxyRunning: Bool = false
    public var blockedCount: Int = 0
    public var isMicActive: Bool = false
    public var tccStatus: TCCAuditStatus = .fullDiskAccessRequired
    
    private let maxBufferLimit = 1000
    private let lock = NSLock()
    private var proxyServer: LocalProxyServer?
    private let blocklistEngine = BlocklistEngine()
    private let sensorWatcher = HardwareSensorWatcher()

    public init() {
        setupBlocklist()
        setupSensors()
        refreshTCC()
    }

    private func setupBlocklist() {
        // Load default known trackers
        let defaults = """
        google-analytics.com
        analytics.google.com
        googletagmanager.com
        doubleclick.net
        adservice.google.com
        graph.facebook.com
        connect.facebook.net
        pixel.facebook.com
        segment.io
        api.segment.io
        telemetry.applovin.com
        crashlytics.com
        """
        blocklistEngine.load(fromString: defaults)
    }

    private func setupSensors() {
        self.isMicActive = HardwareSensorWatcher.isMicrophoneActive()
        sensorWatcher.onSensorChange = { [weak self] event in
            guard let self = self else { return }
            Task { @MainActor in
                self.isMicActive = event.isActive
            }
        }
    }

    public func toggleProxy() {
        if isProxyRunning {
            proxyServer?.stop()
            proxyServer = nil
            isProxyRunning = false
        } else {
            let proxy = LocalProxyServer(port: 8080, blocklist: blocklistEngine)
            proxy.onEvent = { [weak self] event in
                self?.recordNetworkEvent(event)
            }
            do {
                try proxy.start()
                self.proxyServer = proxy
                self.isProxyRunning = true
            } catch {
                print("[AppState] Failed to start proxy: \(error)")
            }
        }
    }

    public func recordNetworkEvent(_ event: NetworkEvent) {
        lock.lock()
        defer { lock.unlock() }

        if event.isBlocked {
            blockedCount += 1
        }

        networkEvents.insert(event, at: 0)
        if networkEvents.count > maxBufferLimit {
            networkEvents.removeLast()
        }
    }

    public func refreshTCC() {
        let (entries, status) = TCCReader.readTCC()
        self.tccEntries = entries
        self.tccStatus = status
    }
}
