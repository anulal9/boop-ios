import Foundation
import CoreBluetooth
import Combine
import UIKit
import SwiftUI

// MARK: - Boop Manager
/// Manages the queue of devices that are in "boop" range (touching distance)
/// Automatically tracks devices that are ≤10cm away with aligned angles
@MainActor
class BoopManager: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var latestBoopEvent: BoopEvent? = nil

    /// Track display names for discovered devices (keyed by sender's local UUID)
    @Published var displayNames: [UUID: String] = [:]

    /// Map peripheral UUIDs to sender's local UUIDs
    private var peripheralToSenderUUID: [UUID: UUID] = [:]

    // MARK: - Private Properties
    private let bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 2.0  // Update every 2 seconds
    private var lastBoopTime: [UUID: Date] = [:]
    private let boopCooldown: TimeInterval = 5.0  // Seconds before allowing another auto-boop
    private lazy var displayName: Task<String, Error> = {
        Task {
            if let profile = await DataStore.shared.getUserProfile() {
                return profile.displayName
            }
            return ""
        }
    }()

    // MARK: - Init
    override init() {
        self.bluetoothManager = BluetoothManager()
        super.init()
        self.bluetoothManager.setBoopDelegate(self)
    }
    
    // MARK: - Setup
    private var previousDevices = Set<UUID>()
    private var previousPositions: [UUID: DevicePositionCategory] = [:]

    private func setupObservers() {
        bluetoothManager.nearbyDevices
            .sink { [weak self] devices in
                guard let self = self else { return }
                self.processNearbyDevicesUpdate(devices)
            }
            .store(in: &cancellables)
    }

    // MARK: - Nearby Device Processing

    private func processNearbyDevicesUpdate(_ devices: [UUID: DevicePositionCategory]) {
        let deviceIDs = Set(devices.keys)

        print("📊 BoopManager: nearbyDevices updated - count: \(deviceIDs.count)")
        print("📊 BoopManager: Device IDs: \(deviceIDs.map { $0.uuidString.prefix(8) })")

        sendPresenceToNewDevices(currentDeviceIDs: deviceIDs)
        checkNearbyDevicesForBoops(devices)
        cleanUpDisconnectedDevices(currentDeviceIDs: deviceIDs)

        previousPositions = devices
        previousDevices = deviceIDs
    }

    private func sendPresenceToNewDevices(currentDeviceIDs: Set<UUID>) {
        let newDevices = currentDeviceIDs.subtracting(previousDevices)
        if !newDevices.isEmpty {
            print("🆕 BoopManager: Detected \(newDevices.count) new device(s)")
        }
        for deviceID in newDevices {
            Task {
                if let displayName = try? await self.displayName.value {
                    let profile = await DataStore.shared.getUserProfile()
                    print("👋 BoopManager: Sending presence to \(deviceID.uuidString.prefix(8)) with name '\(displayName)'")
                    self.bluetoothManager.sendPresence(
                        to: deviceID,
                        displayName: displayName,
                        birthday: profile?.birthday,
                        bio: profile?.bio
                    )
                } else {
                    print("⚠️ BoopManager: Could not get display name for presence")
                }
            }
        }
    }

    private func checkNearbyDevicesForBoops(_ devices: [UUID: DevicePositionCategory]) {
        for (deviceID, position) in devices {
            if position == .ApproxTouching && previousPositions[deviceID] != .ApproxTouching {
                if let lastBoop = lastBoopTime[deviceID],
                   Date().timeIntervalSince(lastBoop) < boopCooldown {
                    print("⏳ BoopManager: Skipping auto-boop for \(deviceID.uuidString.prefix(8)) - cooldown active")
                    continue
                }
                print("🤝 BoopManager: Device \(deviceID.uuidString.prefix(8)) entered touching range - sending boop")
                lastBoopTime[deviceID] = Date()
                Task {
                    _ = await self.sendBluetoothMessage(deviceId: deviceID, messageType: .boop)
                }
            }
        }
    }

    private func cleanUpDisconnectedDevices(currentDeviceIDs: Set<UUID>) {
        displayNames = displayNames.filter { currentDeviceIDs.contains($0.key) }
        lastBoopTime = lastBoopTime.filter { currentDeviceIDs.contains($0.key) }
        print("📊 BoopManager: Current displayNames: \(displayNames.mapValues { $0 })")
    }
    
    func start() {
        setupObservers()
        bluetoothManager.start()
    }
    
    func stop() {
        cancellables.removeAll()
        bluetoothManager.stop()
    }

    // MARK: - Public Methods

    /// Get nearby devices with their display info
    func getNearbyDevices() -> [UUID: DevicePositionCategory] {
        return bluetoothManager.getNearbyDevices()
    }

    private func sendBluetoothMessage(deviceId: UUID,
                                      messageType: BluetoothMessage.MessageType) async -> Bool {
        do {
            // Get user profile data
            let profile = await DataStore.shared.getUserProfile()
            
            let message = BluetoothMessage(
                senderUUID: bluetoothManager.getLocalDeviceUUID(),
                messageType: messageType,
                displayName: try await self.displayName.value,
                birthday: profile?.birthday,
                bio: profile?.bio,
                gradientColors: profile?.gradientColorsData ?? []
            )
            print("Boop: Sending BLE Message with profile data")
            bluetoothManager.sendMessage(message, to: deviceId)
            return true
        } catch {
            print("\(error.localizedDescription) occured")
            return false
        }
    }
}
extension BoopManager: BoopDelegate {
    func didReceiveBoop(from senderUUID: UUID, peripheralUUID: UUID, displayName: String, birthday: Date?, bio: String?, gradientColors: [String]) {
        print("🎉 BoopManager: Received boop from sender: \(senderUUID.uuidString.prefix(8)), peripheral: \(peripheralUUID.uuidString.prefix(8)), displayName: '\(displayName)'")

        // Store mapping and display name
        peripheralToSenderUUID[peripheralUUID] = senderUUID
        displayNames[peripheralUUID] = displayName  // Store by peripheral UUID for UI lookup

        print("💾 BoopManager: Stored display name '\(displayName)' for peripheral \(peripheralUUID.uuidString.prefix(8))")
        print("📊 BoopManager: Total stored names: \(displayNames.count)")

        // Convert gradient color strings to Color objects
        let colors = gradientColors.compactMap { colorString -> Color? in
            switch colorString {
            case "red": return .red
            case "orange": return .orange
            case "yellow": return .yellow
            case "green": return .green
            case "cyan": return .cyan
            case "blue": return .blue
            case "indigo": return .indigo
            case "purple": return .purple
            case "pink": return .pink
            case "mint": return .mint
            case "teal": return .teal
            case "brown": return .brown
            case "white": return .white
            case "black": return .black
            case "gray": return .gray
            default: return nil
            }
        }

        // Create boop object with profile data
        let boop = Boop(senderUUID: senderUUID, displayName: displayName, birthday: birthday, bio: bio, gradientColors: colors)

        // Broadcast event (don't store in queue)
        // Note: Live activity is started in BoopTimelineView.handleNewBoop() where the interaction is created
        latestBoopEvent = BoopEvent(boop: boop)
    }

    func didReceiveBoopRequest(from senderUUID: UUID, peripheralUUID: UUID, displayName: String, birthday: Date?, bio: String?, gradientColors: [String]) {
        print("📨 BoopManager: Received boop request from sender: \(senderUUID.uuidString.prefix(8)), peripheral: \(peripheralUUID.uuidString.prefix(8)), displayName: '\(displayName)'")

        // Store mapping and display name
        peripheralToSenderUUID[peripheralUUID] = senderUUID
        displayNames[peripheralUUID] = displayName  // Store by peripheral UUID for UI lookup

        print("💾 BoopManager: Stored display name '\(displayName)' for peripheral \(peripheralUUID.uuidString.prefix(8))")
        print("📊 BoopManager: Total stored names: \(displayNames.count)")
    }

    func didReceivePresence(from senderUUID: UUID, peripheralUUID: UUID, displayName: String, birthday: Date?, bio: String?, gradientColors: [String]) {
        print("👋 BoopManager: Received presence from sender: \(senderUUID.uuidString.prefix(8)), peripheral: \(peripheralUUID.uuidString.prefix(8)), displayName: '\(displayName)'")

        // Store mapping and display name
        peripheralToSenderUUID[peripheralUUID] = senderUUID
        displayNames[peripheralUUID] = displayName  // Store by peripheral UUID for UI lookup

        print("💾 BoopManager: Stored display name '\(displayName)' for peripheral \(peripheralUUID.uuidString.prefix(8))")
        print("🔗 BoopManager: Mapped peripheral \(peripheralUUID.uuidString.prefix(8)) → sender \(senderUUID.uuidString.prefix(8))")
        print("📊 BoopManager: Total stored names: \(displayNames.count)")
        print("📊 BoopManager: All stored names: \(displayNames)")
    }
}
