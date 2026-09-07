import SwiftUI

public struct DashboardWindowView: View {
    @Bindable public var appState: AppState
    @State private var selectedTab = 0
    @State private var searchQuery = ""

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("TCC Permissions", systemImage: "lock.shield").tag(0)
                Label("Traffic Inspector", systemImage: "network").tag(1)
                Label("Sensor Activity", systemImage: "waveform").tag(2)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            VStack {
                switch selectedTab {
                case 0:
                    tccAuditView
                case 1:
                    trafficFeedView
                case 2:
                    sensorActivityView
                default:
                    Text("Select a view")
                }
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 480)
    }

    private var tccAuditView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TCC Privacy Permissions")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Refresh") {
                    appState.refreshTCC()
                }
            }

            if case .fullDiskAccessRequired = appState.tccStatus {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Full Disk Access (FDA) required to read TCC.db directly.")
                        .font(.caption)
                    Spacer()
                    Button("Grant Access") {
                        if let url = TCCReader.privacySettingsURL(for: "fulldisk") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .controlSize(.small)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            List(filteredTCC) { entry in
                PermissionRow(entry: entry)
            }
            .searchable(text: $searchQuery, prompt: "Filter by app or service...")
        }
    }

    private var filteredTCC: [TCCPermissionEntry] {
        if searchQuery.isEmpty {
            return appState.tccEntries
        }
        return appState.tccEntries.filter {
            $0.humanReadableName.localizedCaseInsensitiveContains(searchQuery) ||
            $0.client.localizedCaseInsensitiveContains(searchQuery) ||
            $0.service.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private var trafficFeedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Outbound Traffic (Zero-Decryption SNI)")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                StatusBadge(
                    title: appState.isProxyRunning ? "Proxy Active (127.0.0.1:8080)" : "Proxy Offline",
                    isActive: appState.isProxyRunning,
                    activeColor: .green
                )
                Button(appState.isProxyRunning ? "Stop" : "Start") {
                    appState.toggleProxy()
                }
            }

            List(appState.networkEvents) { event in
                HStack {
                    Image(systemName: event.isBlocked ? "shield.slash.fill" : "arrow.up.right.circle.fill")
                        .foregroundColor(event.isBlocked ? .red : .blue)
                    VStack(alignment: .leading) {
                        Text(event.domain)
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Port \(event.port) • \(event.timestamp.formatted(date: .omitted, time: .standard))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(event.isBlocked ? "Blocked Tracker" : "Relayed (Clean)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(event.isBlocked ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .foregroundColor(event.isBlocked ? .red : .green)
                        .cornerRadius(4)
                }
            }
        }
    }

    private var sensorActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hardware Sensor Activity")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 24) {
                HStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.largeTitle)
                        .foregroundColor(appState.isMicActive ? .orange : .secondary)
                    VStack(alignment: .leading) {
                        Text("Microphone")
                            .font(.headline)
                        Text(appState.isMicActive ? "Stream Active" : "Idle")
                            .font(.caption)
                            .foregroundColor(appState.isMicActive ? .orange : .secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }

            Spacer()
        }
    }
}
