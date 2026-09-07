import Foundation
import CoreAudio

public enum HardwareSensorType: String, Sendable {
    case microphone = "Microphone"
    case camera = "Camera"
}

public struct SensorEvent: Identifiable, Sendable {
    public let id = UUID()
    public let sensor: HardwareSensorType
    public let isActive: Bool
    public let timestamp: Date
    public let note: String

    public init(sensor: HardwareSensorType, isActive: Bool, timestamp: Date = Date(), note: String = "") {
        self.sensor = sensor
        self.isActive = isActive
        self.timestamp = timestamp
        self.note = note
    }
}

public final class HardwareSensorWatcher: @unchecked Sendable {
    private var isListening = false
    public var onSensorChange: (@Sendable (SensorEvent) -> Void)?

    public init() {}

    /// Checks whether the default audio input device is currently running an active stream
    public static func isMicrophoneActive() -> Bool {
        var defaultInputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultInputDeviceID
        )

        guard status == noErr, defaultInputDeviceID != kAudioDeviceUnknown else {
            return false
        }

        var isRunning: UInt32 = 0
        var isRunningSize = UInt32(MemoryLayout<UInt32>.size)
        var isRunningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let runStatus = AudioObjectGetPropertyData(
            defaultInputDeviceID,
            &isRunningAddress,
            0,
            nil,
            &isRunningSize,
            &isRunning
        )

        return (runStatus == noErr) && (isRunning != 0)
    }

    public func start() {
        guard !isListening else { return }
        isListening = true
        
        let initialStatus = Self.isMicrophoneActive()
        onSensorChange?(SensorEvent(sensor: .microphone, isActive: initialStatus, note: "Watcher initialized"))
        print("[HardwareSensorWatcher] Microphone status polling active (Initial: \(initialStatus))")
    }

    public func stop() {
        isListening = false
        print("[HardwareSensorWatcher] Watcher stopped.")
    }
}
