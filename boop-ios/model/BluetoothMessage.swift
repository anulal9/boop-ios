//
//  BluetoothMessage.swift
//  boop-ios
//

import Foundation

/// Binary protocol for Bluetooth communication
/// Format: [UUID: 16 bytes][MessageType: 1 byte][DisplayNameLength: 1 byte][DisplayName: variable][PayloadLength: 2 bytes][Payload: variable]
struct BluetoothMessage {
    let senderUUID: UUID
    let messageType: MessageType
    let displayName: String
    let payload: Data

    /// Maximum allowed length for display name in bytes (UTF-8 encoded)
    static let maxDisplayNameBytes = 50

    enum MessageType: UInt8 {
        case connectionRequest = 0x01
        case connectionAccept = 0x02
        case connectionReject = 0x03
        case disconnect = 0x05
        case boop = 0x06
    }

    // MARK: - Encoding
    func encode() -> Data {
        var data = Data()

        // Add sender UUID (16 bytes)
        data.append(senderUUID.uuidData)

        // Add message type (1 byte)
        data.append(messageType.rawValue)

        // Truncate display name to max bytes
        let truncatedDisplayName = Self.truncateDisplayName(displayName)
        let displayNameData = truncatedDisplayName.data(using: .utf8) ?? Data()

        // Add display name length (1 byte)
        data.append(UInt8(displayNameData.count))

        // Add display name
        data.append(displayNameData)

        // Add payload length (2 bytes, big-endian)
        let payloadLength = UInt16(payload.count)
        data.append(UInt8(payloadLength >> 8))
        data.append(UInt8(payloadLength & 0xFF))

        // Add payload
        data.append(payload)

        return data
    }

    // MARK: - Decoding
    static func decode(_ data: Data) -> BluetoothMessage? {
        // Minimum size: 16 (UUID) + 1 (type) + 1 (displayNameLength) + 2 (payloadLength) = 20 bytes
        guard data.count >= 20 else {
            print("⚠️ BluetoothMessage decode failed: data too short (\(data.count) bytes)")
            return nil
        }

        // Extract UUID (16 bytes)
        let uuidData = data.subdata(in: 0..<16)
        guard let uuid = UUID(data: uuidData) else {
            print("⚠️ BluetoothMessage decode failed: invalid UUID")
            return nil
        }

        // Extract message type (1 byte)
        guard let messageType = MessageType(rawValue: data[16]) else {
            print("⚠️ BluetoothMessage decode failed: unknown message type \(data[16])")
            return nil
        }

        // Extract display name length (1 byte)
        let displayNameLength = Int(data[17])

        // Validate display name length
        guard data.count >= 20 + displayNameLength else {
            print("⚠️ BluetoothMessage decode failed: display name length mismatch")
            return nil
        }

        // Extract display name
        let displayNameData = data.subdata(in: 18..<(18 + displayNameLength))
        let displayName = String(data: displayNameData, encoding: .utf8) ?? ""

        // Extract payload length (2 bytes) - now offset by displayNameLength
        let payloadLengthOffset = 18 + displayNameLength
        let payloadLength = Int(data[payloadLengthOffset]) << 8 | Int(data[payloadLengthOffset + 1])

        // Validate payload length
        guard data.count >= payloadLengthOffset + 2 + payloadLength else {
            print("⚠️ BluetoothMessage decode failed: payload length mismatch")
            return nil
        }

        // Extract payload
        let payloadOffset = payloadLengthOffset + 2
        let payload = data.subdata(in: payloadOffset..<(payloadOffset + payloadLength))

        return BluetoothMessage(
            senderUUID: uuid,
            messageType: messageType,
            displayName: displayName,
            payload: payload
        )
    }

    // MARK: - Convenience Initializers
    init(senderUUID: UUID, messageType: MessageType, displayName: String = "", payload: Data = Data()) {
        self.senderUUID = senderUUID
        self.messageType = messageType
        self.displayName = displayName
        self.payload = payload
    }

    // MARK: - Helper Methods
    /// Truncates a display name to fit within the maximum byte limit
    /// Ensures we don't cut in the middle of a multi-byte UTF-8 character
    private static func truncateDisplayName(_ name: String) -> String {
        guard let data = name.data(using: .utf8), data.count > maxDisplayNameBytes else {
            return name
        }

        // Truncate to max bytes
        let truncatedData = data.prefix(maxDisplayNameBytes)

        // Try to decode - if it fails, we may have cut a multi-byte character
        // Keep removing bytes until we get a valid string
        for length in stride(from: truncatedData.count, through: 0, by: -1) {
            if let validString = String(data: truncatedData.prefix(length), encoding: .utf8) {
                return validString
            }
        }

        // Fallback to empty string if we can't decode anything
        return ""
    }
}

// MARK: - UUID Extension
extension UUID {
    /// Convert UUID to 16-byte Data
    var uuidData: Data {
        var data = Data(count: 16)
        data.withUnsafeMutableBytes { buffer in
            var uuid = self.uuid
            withUnsafeBytes(of: &uuid) { uuidBuffer in
                buffer.copyMemory(from: uuidBuffer)
            }
        }
        return data
    }

    /// Create UUID from 16-byte Data
    init?(data: Data) {
        guard data.count == 16 else { return nil }
        let bytes = [UInt8](data)
        self.init(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
