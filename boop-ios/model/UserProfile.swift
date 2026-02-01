import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var createdAt: Date
    var avatarData: Data?
    var birthday: Date?
    var bio: String?

    init(name: String, avatarData: Data? = nil, birthday: Date? = nil, bio: String? = nil) {
        self.name = name
        self.avatarData = avatarData
        self.birthday = birthday
        self.bio = bio
        self.createdAt = Date()
    }

    var displayName: String {
        "\(name)"
    }
}
