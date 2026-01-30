import Foundation
import CoreBluetooth
import Combine
import UIKit

// MARK: - Boop Manager
/// Manages the queue of devices that are in "boop" range (touching distance)
/// Automatically tracks devices that are ≤10cm away with aligned angles
@MainActor
class BoopManager: NSObject, ObservableObject {

    // MARK: - Published Properties
    /// Devices currently in touching range (≤10cm, angles aligned)
    @Published var boopQueue = Set<UUID>()
    @Published var boopsToRender: [Boop] = []

    // MARK: - Private Properties
    private let bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 2.0  // Update every 2 seconds
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
        self.bluetoothManager = BluetoothManager(uwbManager: UWBManager())
        super.init()
        self.bluetoothManager.setBoopDelegate(self)
        self.bluetoothManager.start()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe nearbyDevices changes and update boop queue
        bluetoothManager.$nearbyDevices
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.boopTouchingDevices()
            }
            .store(in: &cancellables)
    }

    /// Updates the boop queue by filtering nearby devices for touching distance (sync version)
    private func boopTouchingDevices() {
        print("🔄 Boop: Checking for devices in touching range...")
        
        let touchingDevices = Set(
            bluetoothManager.nearbyDevices.filter
            { key, value in value == DevicePositionCategory.ApproxTouching }.keys)
    
        Task {
            let devicesToAdd = touchingDevices.subtracting(boopQueue)
            for device in devicesToAdd {
                print("🔄 Boop: Adding device \(device) to boopQueue")
                do {
                    let didBoop = try await boopDevice(deviceId: device)
                    if (!didBoop) {
                        print("🔄 Boop: failed boop after 3 retries for device \(device)")
                    }
                } catch {
                    print("🔄 Boop: received error while booping device \(device)")
                }
            }
        }
    }
    
    func receiveBoopAndRemove() throws -> Boop {
        if (!self.boopsToRender.isEmpty) {
            return boopsToRender.popLast()!
        }
        
        throw fatalError("Attempted to render a non-existent boop")
    }
    
    private func boopDevice(deviceId: UUID) async throws -> Bool {
        // Check if device is connected
        var success = false
        var attempts = 0
        while (!success && attempts < 3) {
            success = await sendBluetoothMessage(deviceId: deviceId, messageType: .boop)
            if (success) {
                return true
            }
        }
        return false
    }
    
    private func sendBluetoothMessage(deviceId: UUID,
                                      messageType: BluetoothMessage.MessageType) async -> Bool {
        do {
            let message = BluetoothMessage(
                senderUUID: deviceId,
                messageType: messageType,
                displayName: try await self.displayName.value
            )
            print("Boop: Sending BLE Message")
            bluetoothManager.sendMessage(message, to: deviceId)
            return true
        } catch {
            print("\(error.localizedDescription) occured")
            return false
        }
    }
}
extension BoopManager: BoopDelegate {
    func didReceiveBoop(from senderUUID: UUID, displayName: String) {
        print("Boop: Received boop from \(displayName)")
        boopsToRender.append(Boop(senderUUID: senderUUID, displayName: displayName))
    }
}
