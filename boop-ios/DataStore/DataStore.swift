import Foundation

/// Unified data store providing a single interface for accessing user data
/// Internally uses UserDefaults for persistence with optional in-memory caching
actor DataStore {
    static let shared = DataStore()

    // In-memory cache for frequently accessed values
    private var cache: [String: Any] = [:]
    private var isWarmedUp = false

    private init() {}

    // MARK: - Warmup

    /// Loads frequently accessed data from UserDefaults into memory cache
    /// Should be called during app initialization
    func warmup() async {
        guard !isWarmedUp else { return }

        // Wait for storage initialization to complete before accessing UserDefaults
        try? await StorageCoordinator.shared.waitForInitialization()

        // Pre-load user profile data into cache
        if let name = UserDefaults.standard.string(forKey: UserDefaultsKeys.name) {
            cache[UserDefaultsKeys.name] = name
        }

        if let avatarData = UserDefaults.standard.data(forKey: UserDefaultsKeys.avatarData) {
            cache[UserDefaultsKeys.avatarData] = avatarData
        }

        if let birthday = UserDefaults.standard.object(forKey: UserDefaultsKeys.birthday) as? Date {
            cache[UserDefaultsKeys.birthday] = birthday
        }

        cache[UserDefaultsKeys.profileComplete] = UserDefaults.standard.bool(forKey: UserDefaultsKeys.profileComplete)

        isWarmedUp = true
    }

    // MARK: - User Profile Accessors

    /// Returns the user's name if available
    func getName() async -> String? {
        if let cached = cache[UserDefaultsKeys.name] as? String {
            return cached
        }
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.name)
    }

    /// Returns the user's avatar data if available
    func getAvatarData() async -> Data? {
        if let cached = cache[UserDefaultsKeys.avatarData] as? Data {
            return cached
        }
        return UserDefaults.standard.data(forKey: UserDefaultsKeys.avatarData)
    }

    /// Returns the user's birthday if available
    func getBirthday() async -> Date? {
        if let cached = cache[UserDefaultsKeys.birthday] as? Date {
            return cached
        }
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.birthday) as? Date
    }

    /// Returns whether the user's profile setup is complete
    func isProfileComplete() async -> Bool {
        if let cached = cache[UserDefaultsKeys.profileComplete] as? Bool {
            return cached
        }
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.profileComplete)
    }

    // MARK: - Bulk Profile Operations

    /// Returns all available user profile data
    /// Returns nil if no profile exists
    func getUserProfile() async -> UserProfileData? {
        print("Get UserProfile called")

        guard let name = await getName() else {
            print("No profile found")
            return nil
        }

        let avatarData = await getAvatarData()
        let birthday = await getBirthday()
        let userProfileData = UserProfileData(
            name: name,
            avatarData: avatarData,
            birthday: birthday
        )
        print("Constructed user profile data. Display Name: \(userProfileData.displayName)")
        return userProfileData
    }

    /// Saves user profile data to storage
    /// Updates both cache and UserDefaults
    func setUserProfile(_ profile: UserProfile) async {
        // Update UserDefaults
        UserDefaults.standard.set(profile.name, forKey: UserDefaultsKeys.name)
        if let avatarData = profile.avatarData {
            UserDefaults.standard.set(avatarData, forKey: UserDefaultsKeys.avatarData)
        }
        if let birthday = profile.birthday {
            UserDefaults.standard.set(birthday, forKey: UserDefaultsKeys.birthday)
        }

        // Update cache
        cache[UserDefaultsKeys.name] = profile.name
        if let avatarData = profile.avatarData {
            cache[UserDefaultsKeys.avatarData] = avatarData
        }
        if let birthday = profile.birthday {
            cache[UserDefaultsKeys.birthday] = birthday
        }
    }

    // MARK: - Individual Setters

    /// Sets the profile completion status
    func setProfileComplete(_ isComplete: Bool) async {
        UserDefaults.standard.set(isComplete, forKey: UserDefaultsKeys.profileComplete)
        cache[UserDefaultsKeys.profileComplete] = isComplete
    }

    /// Sets the avatar data
    func setAvatarData(_ data: Data?) async {
        if let data = data {
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.avatarData)
            cache[UserDefaultsKeys.avatarData] = data
        } else {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.avatarData)
            cache.removeValue(forKey: UserDefaultsKeys.avatarData)
        }
    }

    // MARK: - Cache Management

    /// Clears all user data from both cache and UserDefaults
    /// Use this when logging out
    func clear() async {
        // Clear cache
        cache.removeAll()

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.name)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.avatarData)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.birthday)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.profileComplete)

        isWarmedUp = false
    }
}

// MARK: - Data Transfer Object

/// Simple data structure representing user profile data from the store
/// Use this when you need to read multiple profile fields at once
struct UserProfileData {
    let name: String
    let avatarData: Data?
    let birthday: Date?

    var displayName: String {
        "\(name)"
    }
}
