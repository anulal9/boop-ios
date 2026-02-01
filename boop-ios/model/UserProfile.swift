import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var createdAt: Date
    var avatarData: Data?
    var birthday: Date?

    init(name: String, avatarData: Data? = nil, birthday: Date? = nil) {
        self.name = name
        self.avatarData = avatarData
        self.birthday = birthday
        self.createdAt = Date()
    }

    var displayName: String {
        "\(name)"
    }
}
