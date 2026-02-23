# Bluetooth Binary Protocol

## Overview
This app uses a custom binary protocol for Bluetooth Low Energy (BLE) communication instead of plain text strings. This provides type safety, precise schema definition, and efficient data transfer.

## Message Format

```
[Sender UUID: 16 bytes][Message Type: 1 byte][DisplayNameLength: 1 byte][DisplayName: variable][Payload Length: 2 bytes][Payload: variable]
```

**Minimum overhead**: 20 bytes (no display name)

### Field Details

| Field | Size | Type | Description |
|-------|------|------|-------------|
| Sender UUID | 16 bytes | Binary | UUID of the device sending the message |
| Message Type | 1 byte | UInt8 | Type of message (see Message Types below) |
| DisplayNameLength | 1 byte | UInt8 | Length of the display name in bytes (0–255) |
| DisplayName | Variable | UTF-8 | Sender's display name (max 50 bytes UTF-8) |
| Payload Length | 2 bytes | UInt16 (big-endian) | Length of payload in bytes (0–65535) |
| Payload | Variable | Binary | Message-specific data |

## Message Types

```swift
enum MessageType: UInt8 {
    case connectionRequest  = 0x01  // Request to connect
    case connectionAccept   = 0x02  // Accept connection request
    case connectionReject   = 0x03  // Reject connection request
    // 0x04 reserved (previously textMessage, removed)
    case disconnect         = 0x05  // Disconnect notification
    case boop               = 0x06  // Automatic proximity-triggered boop
    case boopRequest        = 0x07  // Manual boop request (reserved for future use)
    case presence           = 0x08  // Announce display name / profile when connecting
    case stoppedRanging     = 0x09  // UWB session ended
}
```

## Implementation

### Encoding Example
```swift
let message = BluetoothMessage(
    senderUUID: localDeviceUUID,
    messageType: .connectionRequest,
    displayName: "Aparna",
    payload: Data()
)
let data = message.encode() // Returns Data
```

### Decoding Example
```swift
if let message = BluetoothMessage.decode(data) {
    print("From: \(message.senderUUID)")
    print("Type: \(message.messageType)")
    print("Name: \(message.displayName)")
    if message.messageType == .presence {
        let profile = message.decodeProfileData()
        // profile.birthday, profile.bio, profile.gradientColors
    }
}
```

## Key Benefits

1. **Type Safety**: Enum-based message types prevent invalid messages
2. **Schema Enforcement**: Fixed 20-byte minimum header ensures consistent format
3. **Sender Identification**: Every message includes sender UUID, solving the CBATTRequest limitation
4. **Display Name Inline**: Display name travels with every message, no separate lookup needed
5. **Compact**: ~20 bytes overhead vs 100+ bytes for JSON
6. **Fast**: Direct byte extraction, no parsing overhead
7. **Extensible**: Easy to add new message types

## Usage in BluetoothManager

### Sending Messages
```swift
// Send a boop message
let message = BluetoothMessage(
    senderUUID: localDeviceUUID,
    messageType: .boop,
    displayName: userDisplayName,
    payload: Data()
)
bluetoothManager.sendMessage(message, to: peripheral)

// Disconnect a peer
bluetoothManager.disconnect(from: peerUUID)
```

### Receiving Messages
Messages are automatically decoded in `peripheralManager(_:didReceiveWrite:)`:
```swift
case .boop:
    delegate?.didReceiveBoop(from: message.senderUUID, displayName: message.displayName)
case .presence:
    let profile = message.decodeProfileData()
    // Handle birthday, bio, gradientColors
case .connectionReject:
    disconnect(from: message.senderUUID)
```

## Future Extensions

The protocol can easily support:
- File transfer (add `.fileTransfer` type)
- Voice messages (add `.audioMessage` type)
- Images (add `.imageMessage` type)
- Custom binary data (add `.binaryData` type)

Simply add new enum cases and handle them in the switch statement.
