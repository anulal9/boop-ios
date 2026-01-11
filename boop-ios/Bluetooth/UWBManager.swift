import Foundation
import NearbyInteraction

// MARK: - Protocol for Dependency Injection
protocol UWBManaging: AnyObject {
    /// Determines if another device is nearby based on distance only (no angle checking)
    /// **Detection**: Uses UWB distance measurement only (≤50cm)
    /// - Parameter deviceID: The UUID of the device to check
    /// - Returns: True if device is within proximity range, regardless of pointing direction
    func isNearby(deviceID: UUID) -> Bool

    /// Determines if devices are approximately touching (≤10cm)
    /// **Detection**: Distance ≤10cm only (no directional checks)
    /// **Use case**: Physical "boop" interaction between devices
    /// - Parameter deviceID: The UUID of the device to check
    /// - Returns: True if devices are within touching distance
    func isApproximatelyTouching(deviceID: UUID) -> Bool

    /// Start UWB ranging session with a peer
    func startRanging(to deviceID: UUID, peerToken: NIDiscoveryToken)

    /// Stop UWB ranging session with a peer
    func stopRanging(to deviceID: UUID)
    
    func setUpDelegate(uwbManagerDelegate: UWBManagerDelegate)

    /// Get the current discovery token for this device
    var discoveryToken: NIDiscoveryToken? { get }
    
}

protocol UWBManagerDelegate: AnyObject {
    func onNearbyObjectsUpdate(updatedObject: UUID) async
}

enum DevicePositionCategory: UInt8 {
    case InRange = 0x01
    case ApproxTouching = 0x02
    case OutOfRange = 0x03
    case Unknown = 0x04
}

// MARK: - UWB Manager Implementation
class UWBManager: NSObject, UWBManaging {

    // MARK: - Configuration
    private struct DistanceThresholds {
        static let touchingDistance: Float = 0.05     // meters (5cm) - touching range
        static let maxDistance: Float = 0.5          // meters (50cm) - maximum proximity range
    }

    // MARK: - Properties
    private var niSession: NISession?
    private var nearbyObjects: [UUID: NINearbyObject] = [:]
    private var deviceTokens: [UUID: NIDiscoveryToken] = [:]
    private var uwbManagerDelegate: UWBManagerDelegate? = nil

    var discoveryToken: NIDiscoveryToken? {
        return niSession?.discoveryToken
    }
    
    init(managerDelegate: UWBManagerDelegate) {
        self.uwbManagerDelegate = managerDelegate
        super.init()
        setupSession()
    }

    // MARK: - Init
    override init() {
        super.init()
        setupSession()
    }

    // MARK: - Setup
    private func setupSession() {
        guard NISession.isSupported else {
            print("❌ UWB: NISession is NOT SUPPORTED on this device")
            return
        }
        
        guard niSession == nil else {
            print("UWB: NISession already exists, skipping setup")
            return
        }

        niSession = NISession()
        niSession?.delegate = self
        
        if let token = niSession?.discoveryToken {
            print("✅ UWB: Session initialized successfully")
            print("📍 UWB: Discovery token available (size: \(try! NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true).count) bytes)")
        } else {
            print("⚠️ UWB: Session initialized but NO DISCOVERY TOKEN available")
        }
    }
    
    func setUpDelegate(uwbManagerDelegate managerDelegate: UWBManagerDelegate) {
        uwbManagerDelegate = managerDelegate
    }

    // MARK: - Public Methods
    func isNearby(deviceID: UUID) -> Bool {
        print("🔍 UWB: isNearby(\(deviceID.uuidString.prefix(8))) called")

        guard let object = nearbyObjects[deviceID] else {
            // No UWB data available for this device
            print("❌ UWB: isNearby(\(deviceID.uuidString.prefix(8))) - NO UWB DATA (not in nearbyObjects)")
            return false
        }

        // Check distance only - no angle requirements
        guard let distance = object.distance else {
            print("❌ UWB: isNearby(\(deviceID.uuidString.prefix(8))) - NO DISTANCE DATA")
            return false
        }

        print("📏 UWB: isNearby(\(deviceID.uuidString.prefix(8))) - distance: \(String(format: "%.3f", distance))m (max: \(DistanceThresholds.maxDistance)m)")

        // Check distance bound - not too far
        let isInRange = distance <= DistanceThresholds.maxDistance

        if isInRange {
            print("✅ UWB: isNearby(\(deviceID.uuidString.prefix(8))) - IN RANGE")
        } else {
            print("❌ UWB: isNearby(\(deviceID.uuidString.prefix(8))) - OUT OF RANGE")
        }

        return isInRange
    }

    func isApproximatelyTouching(deviceID: UUID) -> Bool {
        print("🔍 UWB: isApproximatelyTouching(\(deviceID.uuidString.prefix(8))) called")

        guard let object = nearbyObjects[deviceID] else {
            // No UWB data available for this device
            print("❌ UWB: isApproximatelyTouching(\(deviceID.uuidString.prefix(8))) - NO UWB DATA (not in nearbyObjects)")
            return false
        }

        // Check distance - must be within touching range
        guard let distance = object.distance else {
            print("❌ UWB: isApproximatelyTouching(\(deviceID.uuidString.prefix(8))) - NO DISTANCE DATA")
            return false
        }

        print("📏 UWB: isApproximatelyTouching(\(deviceID.uuidString.prefix(8))) - distance: \(String(format: "%.3f", distance))m (max touching: \(DistanceThresholds.touchingDistance)m)")

        // Check if within touching distance (5cm)
        let isTouching = distance <= DistanceThresholds.touchingDistance

        if isTouching {
            print("✅ UWB: isApproximatelyTouching(\(deviceID.uuidString.prefix(8))) - TOUCHING CONFIRMED")
        } else {
            print("❌ UWB: isApproximatelyTouching(\(deviceID.uuidString.prefix(8))) - TOO FAR (distance: \(String(format: "%.3f", distance))m > \(DistanceThresholds.touchingDistance)m)")
        }

        return isTouching
    }

    func startRanging(to deviceID: UUID, peerToken: NIDiscoveryToken) {
        print("📍 UWB: startRanging() called for \(deviceID.uuidString.prefix(8))")
        
        setupSession() // Recreate for next use
        
        let caps = NISession.deviceCapabilities
        print("precise distance:", caps.supportsPreciseDistanceMeasurement)
        print("direction:", caps.supportsDirectionMeasurement)

        guard let session = niSession else {
            print("❌ UWB: Cannot start ranging - NISession is nil")
            return
        }

        print("📍 UWB: NISession exists, storing token and creating config...")
        deviceTokens[deviceID] = peerToken

        print("📍 UWB: deviceTokens now has \(deviceTokens.count) token(s)")
        print("📍 UWB: nearbyObjects currently has \(nearbyObjects.count) object(s)")

        let config = NINearbyPeerConfiguration(peerToken: peerToken)
        print("📍 UWB: Created NINearbyPeerConfiguration successfully")

        session.run(config)
        print("✅ UWB: Called session.run() - ranging started to \(deviceID.uuidString.prefix(8))")
        print("📍 UWB: Total devices in ranging: \(deviceTokens.count)")
    }

    func stopRanging(to deviceID: UUID) {
        deviceTokens.removeValue(forKey: deviceID)
        nearbyObjects.removeValue(forKey: deviceID)
        niSession?.invalidate()
        niSession = nil

        print("📍 UWB: Stopped ranging to \(deviceID.uuidString.prefix(8))")
    }

    // MARK: - Helper
    private func deviceID(for token: NIDiscoveryToken) -> UUID? {
        return deviceTokens.first(where: { $0.value == token })?.key
    }

    // MARK: - Diagnostics
    func printDiagnostics() {
        print("🔍 UWB: === DIAGNOSTICS ===")
        print("🔍 UWB: NISession supported: \(NISession.isSupported)")
        print("🔍 UWB: NISession exists: \(niSession != nil)")
        print("🔍 UWB: Discovery token exists: \(niSession?.discoveryToken != nil)")
        print("🔍 UWB: Device tokens count: \(deviceTokens.count)")
        print("🔍 UWB: Nearby objects count: \(nearbyObjects.count)")
        if !deviceTokens.isEmpty {
            print("🔍 UWB: Devices with tokens:")
            for (deviceID, _) in deviceTokens {
                print("   - \(deviceID.uuidString.prefix(8))")
            }
        }
        if !nearbyObjects.isEmpty {
            print("🔍 UWB: Nearby objects:")
            for (deviceID, object) in nearbyObjects {
                print("   - \(deviceID.uuidString.prefix(8)): distance=\(object.distance?.description ?? "nil"), direction=\(object.direction != nil ? "available" : "nil")")
            }
        }
        print("🔍 UWB: ==================")
    }
}

// MARK: - NISession Delegate
extension UWBManager: NISessionDelegate {
    nonisolated func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        Task { @MainActor in
            print("📡 UWB: Session didUpdate called with \(nearbyObjects.count) object(s)")
            for object in nearbyObjects {
                let token = object.discoveryToken
                guard let deviceID = deviceID(for: token) else {
                    print("⚠️ UWB: Received update for unknown token")
                    continue
                }

                self.nearbyObjects[deviceID] = object
                await self.uwbManagerDelegate?.onNearbyObjectsUpdate(updatedObject: deviceID)

                if let distance = object.distance {
                    print("📏 UWB: UPDATE \(deviceID.uuidString.prefix(8)) - distance: \(String(format: "%.3f", distance))m")
                } else {
                    print("⚠️ UWB: UPDATE \(deviceID.uuidString.prefix(8)) - NO DISTANCE DATA")
                }
            }
        }
    }

    nonisolated func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        Task { @MainActor in
            for object in nearbyObjects {
                let token = object.discoveryToken
                guard let deviceID = deviceID(for: token) else {
                    continue
                }

                self.nearbyObjects.removeValue(forKey: deviceID)
                print("📍 UWB: Lost connection to \(deviceID.uuidString.prefix(8)), reason: \(reason.rawValue)")
            }
            printDiagnostics()
        }
    }

    nonisolated func session(_ session: NISession, didInvalidateWith error: Error) {
        Task { @MainActor in
            print("⚠️ UWB: Session invalidated - \(error.localizedDescription)")
            nearbyObjects.removeAll()
            niSession = nil
            printDiagnostics()
        }
    }

    nonisolated func sessionWasSuspended(_ session: NISession) {
        Task { @MainActor in
            print("⚠️ UWB: Session suspended")
            printDiagnostics()
        }
    }

    nonisolated func sessionSuspensionEnded(_ session: NISession) {
        Task { @MainActor in
            print("✅ UWB: Session resumed")
            printDiagnostics()
            self.deviceTokens.forEach { (deviceId: UUID, token: NIDiscoveryToken) in
                self.startRanging(to: deviceId, peerToken: token)
            }
        }
    }
    nonisolated func sessionDidStartRunning(_ session: NISession) {
        Task { @MainActor in
            print("UWB: Session did start running")
            printDiagnostics()
        }
    }
}
