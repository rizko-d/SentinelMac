import SwiftUI

public struct StatusBadge: View {
    public let title: String
    public let isActive: Bool
    public let activeColor: Color
    
    public init(title: String, isActive: Bool, activeColor: Color = .green) {
        self.title = title
        self.isActive = isActive
        self.activeColor = activeColor
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? activeColor : Color.secondary.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .primary : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(Capsule())
    }
}

public struct PermissionRow: View {
    public let entry: TCCPermissionEntry
    
    public init(entry: TCCPermissionEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.humanReadableName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(entry.client)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(entry.service)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            
            Image(systemName: entry.allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(entry.allowed ? .green : .red)
            
            Button("Settings") {
                if let url = TCCReader.privacySettingsURL(for: entry.service) {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}
