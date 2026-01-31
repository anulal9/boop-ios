import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var createdAt: Date
    var avatarData: Data?

    init(name: String, avatarData: Data? = nil) {
        self.name = name
        self.avatarData = avatarData
        self.createdAt = Date()
    }

    var displayName: String {
        "\(name)"
    }
}
