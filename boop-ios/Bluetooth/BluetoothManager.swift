import Foundation
import CoreBluetooth
import Combine
import UIKit
import NearbyInteraction

@MainActor
class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var nearbyDevices: [UUID: DevicePositionCategory] = [:]
    @Published var connectionRequests: [UUID: ConnectionRequest] = [:]
    @Published var connectionResponses: [UUID: ConnectionResponse] = [:]
    
    var discoveredDevices: [UUID: CBPeripheral] = [:]

    // MARK: - Internal State
    var connectedPeripherals: [UUID: CBPeripheral] = [:]

    /// Local device UUID - persisted across app launches
    private(set) lazy var localDeviceUUID: UUID = {
        let key = "com.boop.localDeviceUUID"
        if let uuidString = UserDefaults.standard.string(forKey: key),
           let uuid = UUID(uuidString: uuidString) {
            return uuid
        }
        let newUUID = UUID()
        UserDefaults.standard.set(newUUID.uuidString, forKey: key)
        return newUUID
    }()

    // MARK: - Dependencies
    private var service: BluetoothManagerServiceImpl!
    private var uwbManager: UWBManaging?

    // Track UWB token exchange
    private var devicesWithUWBRanging: Set<UUID> = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(uwbManager: UWBManaging? = nil, boopDelegate: BoopDelegate? = nil) {
        self.uwbManager = uwbManager
        super.init()

        // Create service with UWB token
        
        service = BluetoothManagerServiceImpl()
        service.delegate = self
        service.updateUWBToken(uwbDiscoveryToken)
        if let boopDelegate = boopDelegate {
            service.setBoopDelegate(boopDelegate: boopDelegate)
        }
        // Set up observer for nearbyDevices changes to manage UWB ranging
        setupUWBObserver()
    }

    // MARK: - Public Methods
    func setBoopDelegate(_ delegate: BoopDelegate) {
        service.setBoopDelegate(boopDelegate: delegate)
    }

    func start() {
        uwbManager?.setUpDelegate(uwbManagerDelegate: self)
        Task {
            await service.start()
        }
    }

    func stop() {
        Task {
            await service.stop()
        }
        devicesWithUWBRanging.removeAll()
        connectedPeripherals.removeAll()
        discoveredDevices.removeAll()
        nearbyDevices.removeAll()
        connectionRequests.removeAll()
        connectionResponses.removeAll()
    }

    func getNearbyDevices() -> [UUID: DevicePositionCategory] {
        return nearbyDevices
    }

    func getLocalDeviceUUID() -> UUID {
        return localDeviceUUID
    }

    func sendMessage(_ message: BluetoothMessage, to device: UUID) {
        guard let peripheral = connectedPeripherals[device] else {
            print("❌ BT Manager: Cannot find peripheral for device \(device.uuidString.prefix(8))")
            print("📊 BT Manager: Connected peripherals: \(connectedPeripherals.keys.map { $0.uuidString.prefix(8) })")
            return
        }
        print("✅ BT Manager: Found peripheral, sending \(message.messageType) message to \(device.uuidString.prefix(8))")
        Task {
            await service.sendMessage(message, to: peripheral)
        }
    }

    func sendPresence(to device: UUID, displayName: String) {
        print("📤 BT Manager: Sending presence to \(device.uuidString.prefix(8))")
        print("📤 BT Manager: My UUID: \(localDeviceUUID.uuidString.prefix(8)), My displayName: '\(displayName)'")
        let message = BluetoothMessage(
            senderUUID: localDeviceUUID,
            messageType: .presence,
            displayName: displayName
        )
        sendMessage(message, to: device)
    }

    func disconnect(from deviceID: UUID) {
        Task {
            guard let peripheral = connectedPeripherals[deviceID] else {
                return
            }
            await service.disconnect(from: peripheral)
        }
        
    }

    // MARK: - UWB Integration
    private func setupUWBObserver() {
        // Observe changes to nearbyDevices and manage UWB ranging
        $nearbyDevices
            .sink { [weak self] devices in
                guard let self = self else { return }
                self.syncUWBRanging(with: Set(devices.keys))
            }
            .store(in: &cancellables)
    }

    private func syncUWBRanging(with currentDevices: Set<UUID>) {
        print("🔄 BT Manager: syncUWBRanging called")
        print("📊 BT Manager: Current state - discoveredDevices: \(discoveredDevices.count), nearbyDevices: \(nearbyDevices.count), devicesWithUWBRanging: \(devicesWithUWBRanging.count), connectedPeripherals: \(connectedPeripherals.count)")
        print("📋 BT Manager: nearbyDevices: [\(nearbyDevices.keys.map { $0.uuidString.prefix(8) }.joined(separator: ", "))]")
        print("📋 BT Manager: devicesWithUWBRanging: [\(devicesWithUWBRanging.map { $0.uuidString.prefix(8) }.joined(separator: ", "))]")
        print("📋 BT Manager: connectedPeripherals: [\(connectedPeripherals.keys.map { $0.uuidString.prefix(8) }.joined(separator: ", "))]")

        // Stop ranging for devices that are no longer nearby
        let devicesToRemove = devicesWithUWBRanging.subtracting(currentDevices)
        if !devicesToRemove.isEmpty {
            print("🛑 BT Manager: Stopping UWB ranging for \(devicesToRemove.count) device(s)")
            for deviceID in devicesToRemove {
                uwbManager?.stopRanging(to: deviceID)
                devicesWithUWBRanging.remove(deviceID)
                print("📍 BT Manager: Stopped UWB ranging for: \(deviceID.uuidString.prefix(8))")
                disconnect(from: deviceID)
                print("📍 BT Manager: Disconnected from \(deviceID.uuidString.prefix(8))")
            }
        }

        // Start ranging for new devices (will exchange tokens on connect)
        let newDevices = currentDevices.subtracting(devicesWithUWBRanging)
        if !newDevices.isEmpty {
            print("🆕 BT Manager: New devices detected, will start UWB ranging for \(newDevices.count) device(s)")
            for deviceID in newDevices {
                // Connect to device to exchange UWB tokens
                print("📍 BT Manager: Connecting to exchange UWB tokens with: \(deviceID.uuidString.prefix(8))")
                guard let peripheral = connectedPeripherals[deviceID] else {
                    print("cannot find lah")
                    return
                }
                Task {
                    await service.connect(to: peripheral)
                }
            }
        }

        print("📊 BT Manager: After sync - devicesWithUWBRanging: \(devicesWithUWBRanging.count), connectedPeripherals: \(connectedPeripherals.count)")
    }

    // MARK: - Async UWB Methods

    /// Async version: Checks if a device is nearby using UWB distance only
    func isNearbyAsync(deviceID: UUID) async -> Bool {
        return uwbManager?.isNearby(deviceID: deviceID) ?? false
    }

    /// Async version: Checks if devices are approximately touching (≤10cm)
    func isApproximatelyTouchingAsync(deviceID: UUID) async -> Bool {
        return uwbManager?.isApproximatelyTouching(deviceID: deviceID) ?? false
    }

    /// Get the UWB discovery token for this device
    var uwbDiscoveryToken: Data? {
        guard let token = uwbManager?.discoveryToken else { return nil }
        return try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    }

    // MARK: - Diagnostics

    /// Print comprehensive diagnostics for debugging UWB and BLE state
    func printDiagnostics() {
        print("🔍 === BLUETOOTH MANAGER DIAGNOSTICS ===")
        print("🔍 Nearby devices: \(nearbyDevices.count)")
        print("🔍 Connected peripherals: \(connectedPeripherals.count)")
        print("🔍 Devices with UWB ranging: \(devicesWithUWBRanging.count)")
        print("🔍 UWB Manager exists: \(uwbManager != nil)")

        if !nearbyDevices.isEmpty {
            print("🔍 Nearby devices list:")
            for deviceID in nearbyDevices.keys {
                let isConnected = connectedPeripherals[deviceID] != nil
                let hasUWB = devicesWithUWBRanging.contains(deviceID)
                print("   - \(deviceID.uuidString.prefix(8)): connected=\(isConnected), uwb=\(hasUWB)")
            }
        }

        if let uwbMgr = uwbManager as? UWBManager {
            uwbMgr.printDiagnostics()
        } else {
            print("⚠️ UWB Manager not available for diagnostics")
        }
        print("🔍 =====================================")
    }
}

// MARK: - BluetoothServiceDelegate
extension BluetoothManager: BluetoothServiceDelegate {
    func didInvalidateService(_ deviceID: UUID, peripheral: CBPeripheral) {
        self.nearbyDevices.removeValue(forKey: deviceID)
    }
    
    func didReceiveUWBTokenUpdate(for peripheral: CBPeripheral, newToken: NIDiscoveryToken) {
        uwbManager?.registerPeerDiscoveryToken(from: peripheral.identifier, token: newToken)
    }
    

    func didDiscover(_ deviceID: UUID, peripheral: CBPeripheral, rssi: NSNumber) {
            Task {
                if discoveredDevices[deviceID] == nil {
                    discoveredDevices[deviceID] = peripheral
                    print("✅ BT Manager: Added device to discoveredDevices - total: \(discoveredDevices.count)")
                await service.connect(to: peripheral)
            }
        }
    }

    func didRemoveDevice(_ deviceID: UUID) {
        print("🗑️ BT Manager: didRemoveDevice(\(deviceID.uuidString.prefix(8)))")
        // Remove from nearby devices
        discoveredDevices.removeValue(forKey: deviceID)
        nearbyDevices.removeValue(forKey: deviceID)
        connectedPeripherals.removeValue(forKey: deviceID)
        
        print("✅ BT Manager: Removed device from nearbyDevices - total: \(nearbyDevices.count)")
        print("📊 BT Manager: State after removal - discoveredDevices: \(discoveredDevices.count), nearbyDevices: \(nearbyDevices.count), connectedPeripherals: \(connectedPeripherals.count), devicesWithUWBRanging: \(devicesWithUWBRanging.count)")
    }

    func didConnect(to deviceID: UUID, peripheral: CBPeripheral) {
        print("🔗 BT Manager: didConnect(\(deviceID.uuidString.prefix(8)))")
        if !connectedPeripherals.keys.contains(deviceID) {
            connectedPeripherals[deviceID] = peripheral
            print("✅ BT Manager: Added peripheral to connectedPeriphals - total: \(connectedPeripherals.count)")
        }
        print("📊 BT Manager: State after discovery - discoveredDevices: \(discoveredDevices.count), nearbyDevices: \(nearbyDevices.count), connectedPeripherals: \(connectedPeripherals.count), devicesWithUWBRanging: \(devicesWithUWBRanging.count)")
    }

    func didDisconnect(from deviceID: UUID) {
        print("🔌 BT Manager: didDisconnect(\(deviceID.uuidString.prefix(8)))")
        
        connectedPeripherals.removeValue(forKey: deviceID)
        discoveredDevices.removeValue(forKey: deviceID)
        nearbyDevices.removeValue(forKey: deviceID)
        uwbManager = UWBManager(managerDelegate: self)
        service.updateUWBToken(uwbDiscoveryToken)
        
        print("✅ BT Manager: Removed from connectedPeripherals - total: \(connectedPeripherals.count)")
        print("📊 BT Manager: State after disconnect - discoveredDevices: \(discoveredDevices.count), nearbyDevices: \(nearbyDevices.count), connectedPeripherals: \(connectedPeripherals.count), devicesWithUWBRanging: \(devicesWithUWBRanging.count)")
    }

    func didReceiveConnectionRequest(from senderUUID: UUID) {
        print("📨 BT Manager: didReceiveConnectionRequest(\(senderUUID.uuidString.prefix(8)))")
        connectionRequests[senderUUID] = ConnectionRequest(requesterUUID: senderUUID)
    }

    func didReceiveConnectionAccept(from senderUUID: UUID) {
        print("✅ BT Manager: didReceiveConnectionAccept(\(senderUUID.uuidString.prefix(8)))")
        connectionResponses[senderUUID] = ConnectionResponse(requesterUUID: senderUUID, accepted: true)
    }

    func didReceiveConnectionReject(from senderUUID: UUID) {
        print("❌ BT Manager: didReceiveConnectionReject(\(senderUUID.uuidString.prefix(8)))")
        connectionResponses[senderUUID] = ConnectionResponse(requesterUUID: senderUUID, accepted: false)
    }

    func didReceiveDisconnect(from senderUUID: UUID) {
        print("🔌 BT Manager: didReceiveDisconnect(\(senderUUID.uuidString.prefix(8)))")
        self.disconnect(from: senderUUID)
    }

    func didExchangeUWBToken(for deviceID: UUID, token: NIDiscoveryToken) {
        print("📍 BT Manager: didExchangeUWBToken(\(deviceID.uuidString.prefix(8)))")
        // Start UWB ranging with this peer
        uwbManager?.startRanging(to: deviceID, peerToken: token)
        devicesWithUWBRanging.insert(deviceID)
        print("✅ BT Manager: Started UWB ranging with \(deviceID.uuidString.prefix(8)) - total ranging: \(devicesWithUWBRanging.count)")
        print("📊 BT Manager: State after UWB token exchange - discoveredDevices: \(discoveredDevices.count), nearbyDevices: \(nearbyDevices.count), connectedPeripherals: \(connectedPeripherals.count), devicesWithUWBRanging: \(devicesWithUWBRanging.count)")
    }
}
// MARK: - BluetoothServiceDelegate
extension BluetoothManager: UWBManagerDelegate {
    
    func onNearbyObjectsUpdate(updatedObject: UUID) async {
        let currentState = nearbyDevices[updatedObject] ?? DevicePositionCategory.Unknown
        var newState = DevicePositionCategory.Unknown
        if await isApproximatelyTouchingAsync(deviceID: updatedObject) {
            newState = DevicePositionCategory.ApproxTouching
        } else if await isNearbyAsync(deviceID: updatedObject) {
            newState = DevicePositionCategory.InRange
        } else {
            newState = DevicePositionCategory.OutOfRange
        }
        if newState != currentState {
            nearbyDevices[updatedObject] = newState
        }
    }
    
    
}
