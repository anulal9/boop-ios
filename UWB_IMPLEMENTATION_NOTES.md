# UWB Bidirectional Ranging Implementation Notes

## Overview
This document tracks the implementation of bidirectional UWB (Ultra-Wideband) ranging for the boop-ios app. The app uses BLE for device discovery and UWB for precise proximity and direction detection.

## Recent Bug Fixes

### 1. UWB Characteristic Caching Issue
**Problem**: App crashed with "Characteristics with cached values must be read-only" when trying to make UWB characteristic writeable.

**Solution**: Changed characteristic initialization in `BluetoothManagerService.swift:150-155`:
```swift
uwbTokenCharacteristic = CBMutableCharacteristic(
    type: uwbTokenCharacteristicUUID,
    properties: [.read, .write],
    value: nil,  // Must be nil for writeable characteristics (not uwbDiscoveryTokenData)
    permissions: [.readable, .writeable]
)
```

**Key Learning**: CoreBluetooth enforces that characteristics with pre-populated values must be read-only. Use `value: nil` and handle dynamically via `peripheralManager(_:didReceiveRead:)`.

### 2. Missing UWB Permission
**Problem**: "NIERROR_USER_DID_NOT_ALLOW_DESCRIPTION" error when starting UWB session.

**Solution**: Added permission description to `project.pbxproj` (lines ~258-260):
```
INFOPLIST_KEY_NSNearbyInteractionUsageDescription = "This app uses Ultra Wideband to accurately detect when devices are close together for the boop feature.";
```

**Result**: Permission prompt now appears and UWB works after user grants permission.

### 3. CRITICAL: Missing session.run() Call
**Problem**: UWB nearbyObjects array was always empty - no ranging updates received.

**Solution**: Added the missing `session.run(config)` call in `UWBManager.swift:241`:
```swift
func startRanging(to deviceID: UUID, token: NIDiscoveryToken) {
    let config = NINearbyPeerConfiguration(peerToken: token)
    session.run(config)  // ⚠️ THIS WAS MISSING
    print("✅ UWB: Called session.run() - ranging started")
}
```

**Result**: UWB ranging now starts properly and nearbyObjects receives updates.

### 4. Missing Direction Data (Bidirectional Ranging)
**Problem**: UWB distance was working but direction was always nil.

**Root Cause**: Direction data requires **bidirectional ranging** - both devices must range to each other simultaneously. Only the central device was starting ranging; the peripheral side wasn't.

**Solution**: Modified `BluetoothManagerService.swift` to start ranging from both sides:

#### Changes Made:

1. **Added central tracking** (line 59):
```swift
private var connectedCentrals: [UUID: CBCentral] = [:]
```

2. **Track centrals on read** (lines 309-327):
```swift
func peripheralManager(_ peripheral: CBPeripheralManager,
                      didReceiveRead request: CBATTRequest) {
    if request.characteristic.uuid == uwbTokenCharacteristicUUID {
        let central = request.central
        connectedCentrals[central.identifier] = central
        // ... provide token
    }
}
```

3. **Start ranging on peripheral side** (lines 270-304):
```swift
else if request.characteristic.uuid == uwbTokenCharacteristicUUID {
    if let tokenData = request.value {
        let central = request.central  // Not optional!
        if let token = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: NIDiscoveryToken.self,
            from: tokenData
        ) {
            let peerID = central.identifier
            print("📍 BLE Service: Received UWB token via write from central \(peerID.uuidString.prefix(8))")

            connectedCentrals[peerID] = central

            // ⚠️ KEY FIX: Start ranging from peripheral side too!
            print("✅ BLE Service: Starting bidirectional UWB ranging from peripheral side")
            Task { @MainActor in
                self.delegate?.didExchangeUWBToken(for: peerID, token: token)
            }

            peripheralManager.respond(to: request, withResult: .success)
        }
    }
}
```

**Flow Now**:
- Device A (central) → connects to B → reads B's token → writes A's token → **A starts ranging to B** ✅
- Device B (peripheral) → receives A's token via write → **B starts ranging to A** ✅
- Both devices ranging = direction data available 🎯

## Architecture Overview

### Core Components

```
┌─────────────────────────────────────────────────────────┐
│                    BluetoothManager                     │
│  (@MainActor, ObservableObject)                         │
│  - Holds @Published state (nearbyDevices, boops, etc.)  │
│  - Provides sync/async UWB query methods                │
│  - Manages UWB ranging lifecycle                        │
└──────────────────┬──────────────────────────────────────┘
                   │ delegates to
                   ▼
┌─────────────────────────────────────────────────────────┐
│              BluetoothManagerService                    │
│  (nonisolated, async backend)                           │
│  - CBPeripheralManager (advertising)                    │
│  - CBCentralManager (scanning)                          │
│  - Handles BLE operations & token exchange              │
│  - Tracks connectedCentrals for bidirectional ranging   │
└──────────────────┬──────────────────────────────────────┘
                   │ coordinates with
                   ▼
┌─────────────────────────────────────────────────────────┐
│                     UWBManager                          │
│  (@MainActor)                                           │
│  - NISession for UWB ranging                            │
│  - Manages nearbyObjects                                │
│  - Provides distance/direction/angle queries            │
│  - session.run() for each peer token                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     BoopManager                         │
│  (@MainActor, ObservableObject)                         │
│  - Subscribes to bluetoothManager.nearbyDevices (Combine)│
│  - compareNearbyDevicesUpdate() auto-boops at ≤7cm      │
│  - @Published latestBoopEvent drives UI and persistence  │
└─────────────────────────────────────────────────────────┘
```

### Key Files

- **`boop-ios/Bluetooth/BluetoothManagerService.swift`**: BLE backend handling advertising, scanning, and token exchange
- **`boop-ios/Bluetooth/BluetoothManager.swift`**: MainActor wrapper with @Published state and UWB integration
- **`boop-ios/Bluetooth/UWBManager.swift`**: UWB ranging session management and proximity detection
- **`boop-ios/Bluetooth/UWBService.swift`**: Distance threshold evaluation (7cm touching, 100cm max)
- **`boop-ios/BoopManager.swift`**: Combine-based orchestrator; triggers automatic boop at touching range

## Additional Features Implemented

### Diagnostics Logging

Added comprehensive diagnostics to both `UWBManager` and `BluetoothManager`:
- Device counts, connection states, ranging status
- Token availability and sizes
- NISession support checking
- Per-device status breakdowns

Call `bluetoothManager.printDiagnostics()` to see full state.

## Testing Checklist

### Verify Bidirectional Ranging

Run on two physical devices and check logs for:

**On both devices:**
```
✅ UWB: Session initialized successfully
📍 UWB: Discovery token available (size: XXX bytes)
```

**On device acting as central:**
```
🔗 BLE Service: Connected to peripheral XXXXXXXX
📍 BLE Service: Reading UWB token from XXXXXXXX
📍 BLE Service: Writing our UWB token to XXXXXXXX
✅ UWB: Called session.run() - ranging started to XXXXXXXX
```

**On device acting as peripheral:**
```
📍 BLE Service: Received UWB token via write from central XXXXXXXX
✅ BLE Service: Starting bidirectional UWB ranging from peripheral side
✅ UWB: Called session.run() - ranging started to XXXXXXXX
```

**Direction data (both devices):**
```
📍 UWB: nearbyObject - distance: X.Xm, direction: <vector value>
```

### Test Proximity Detection

1. **Discovery**: Devices should appear in nearbyDevices within ~2 seconds
2. **Distance**: Move devices closer/farther, check distance updates
3. **Direction**: Point devices at each other, verify direction vector changes
4. **Touching**: Bring devices within 7cm, verify `ApproxTouching` category is set in `nearbyDevices`
5. **Removal**: Move devices far apart, verify removal from nearbyDevices

### Test Boop Flow

1. Bring two devices within 7cm (approximately touching)
2. Verify `BoopManager` detects `.ApproxTouching` state via `compareNearbyDevicesUpdate`
3. Observe that a `.boop` BLE message is sent automatically (no user action required)
4. Verify `didReceiveBoop` fires on the receiving device
5. Confirm `latestBoopEvent` is set and `BoopInteraction` is created in SwiftData

## Known Issues & Warnings

### Edge Cases to Handle

1. **Connection drops during token exchange**: Currently no retry logic
2. **UWB permission denied**: App should gracefully degrade to BLE-only mode
3. **Device goes out of range during token write**: Write may fail silently
4. **Multiple simultaneous connections**: Needs testing with 3+ devices

## Build Information

**Last Successful Build**: 2025-11-27

**Build Command**:
```bash
xcodebuild -scheme boop-ios -destination 'id=73770497-2A80-49FC-B44D-D3DD0B34BF94' build
```

**Deployment Target**: iOS 18.2
**Swift Version**: 6.0

## Next Steps

1. **Test bidirectional ranging on physical devices** - Verify direction data appears
2. **Test with multiple devices** - Ensure 3+ device scenarios work
3. **Add error handling** - Handle permission denials, connection failures, token exchange errors
4. **Clean up warnings** - Fix the var/let issues in BoopManager
5. **Add unit tests** - Test proximity calculations, queue management
6. **Performance testing** - Monitor battery usage with continuous UWB ranging

## References

- **CoreBluetooth Documentation**: https://developer.apple.com/documentation/corebluetooth
- **Nearby Interaction Framework**: https://developer.apple.com/documentation/nearbyinteraction
- **NISession Best Practices**: https://developer.apple.com/documentation/nearbyinteraction/nisession

---

**Last Updated**: 2026-02-22
**Status**: ✅ Bidirectional ranging implemented, automatic proximity-based boop flow active
