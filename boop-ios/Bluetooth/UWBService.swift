//
//  UWBService.swift
//  boop-ios
//

import Foundation
import NearbyInteraction

protocol IUWBService {
    
    /// Determines if another device is nearby based on distance only (no angle checking)
    /// **Detection**: Uses UWB distance measurement only (≤50cm)
    /// - Parameter deviceID: The UUID of the device to check
    /// - Returns: True if device is within proximity range, regardless of pointing direction
    func isNearby(nearbyObject: NINearbyObject) -> Bool

    /// Determines if devices are approximately touching (≤10cm)
    /// **Detection**: Distance ≤10cm only (no directional checks)
    /// **Use case**: Physical "boop" interaction between devices
    /// - Parameter deviceID: The UUID of the device to check
    /// - Returns: True if devices are within touching distance
    func isApproximatelyTouching(nearbyObject: NINearbyObject) -> Bool

}

class UWBService: IUWBService {
    
    // MARK: - Configuration
    private struct DistanceThresholds {
        static let touchingDistance: Float = 0.05     // meters (5cm) - touching range
        static let maxDistance: Float = 1          // meters (100cm) - maximum proximity range
    }
    
    
    func isNearby(nearbyObject: NINearbyObject) -> Bool {
        
        // Check distance only - no angle requirements
        guard let distance = nearbyObject.distance else {
            print("❌ UWB: isNearby - NO DISTANCE DATA")
            return false
        }

        print("📏 UWB: isNearby - distance: \(String(format: "%.3f", distance))m (max: \(DistanceThresholds.maxDistance)m)")

        // Check distance bound - not too far
        let isInRange = distance <= DistanceThresholds.maxDistance
        if (isInRange) {
            print("✅ UWB: isNearby = \(isInRange)")
        } else {
            print("❌ UWB: isNearby = \(isInRange)")
        }
        return isInRange
    }
    
    func isApproximatelyTouching(nearbyObject: NINearbyObject) -> Bool {

        // Check distance - must be within touching range
        guard let distance = nearbyObject.distance else {
            print("❌ UWB: isApproximatelyTouching - NO DISTANCE DATA")
            return false
        }

        print("📏 UWB: isApproximatelyTouching - distance: \(String(format: "%.3f", distance))m (max touching: \(DistanceThresholds.touchingDistance)m)")

        // Check if within touching distance (5cm)
        let isTouching = distance <= DistanceThresholds.touchingDistance

        if isTouching {
            print("✅ UWB: isApproximatelyTouching() - TOUCHING CONFIRMED")
        } else {
            print("❌ UWB: isApproximatelyTouching() - TOO FAR (distance: \(String(format: "%.3f", distance))m > \(DistanceThresholds.touchingDistance)m)")
        }

        return isTouching
    }
    
}
