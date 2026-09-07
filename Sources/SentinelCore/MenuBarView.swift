import SwiftUI

public struct MenuBarView: View {
    @Bindable public var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SentinelMac")
                    .font(.headline)
                Spacer()
                StatusBadge(
                    title: appState.isProxyRunning ? "Protected" : "Inactive",
                    isActive: appState.isProxyRunning
                )
            }
            
            Divider()
            
            HStack {
                Text("Trackers Blocked:")
                    .font(.subheadline)
                Spacer()
                Text("\(appState.blockedCount)")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            HStack {
                Text("Active Microphone:")
                    .font(.subheadline)
                Spacer()
                Text(appState.isMicActive ? "ACTIVE" : "Idle")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(appState.isMicActive ? .orange : .green)
            }
            
            Divider()
            
            HStack {
                Button(appState.isProxyRunning ? "Stop Guard" : "Start Guard") {
                    appState.toggleProxy()
                }
                .buttonStyle(.borderedProminent)
                .tint(appState.isProxyRunning ? .red : .blue)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(12)
        .frame(width: 260)
    }
}
