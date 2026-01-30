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
        if let firstName = UserDefaults.standard.string(forKey: UserDefaultsKeys.firstName) {
            cache[UserDefaultsKeys.firstName] = firstName
        }
        if let lastName = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastName) {
            cache[UserDefaultsKeys.lastName] = lastName
        }
        if let birthDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.birthDate) as? Date {
            cache[UserDefaultsKeys.birthDate] = birthDate
        }
        if let avatarData = UserDefaults.standard.data(forKey: UserDefaultsKeys.avatarData) {
            cache[UserDefaultsKeys.avatarData] = avatarData
        }

        cache[UserDefaultsKeys.profileComplete] = UserDefaults.standard.bool(forKey: UserDefaultsKeys.profileComplete)

        isWarmedUp = true
    }

    // MARK: - User Profile Accessors

    /// Returns the user's first name if available
    func getFirstName() async -> String? {
        if let cached = cache[UserDefaultsKeys.firstName] as? String {
            return cached
        }
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.firstName)
    }

    /// Returns the user's last name if available
    func getLastName() async -> String? {
        if let cached = cache[UserDefaultsKeys.lastName] as? String {
            return cached
        }
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.lastName)
    }

    /// Returns the user's birth date if available
    func getBirthDate() async -> Date? {
        if let cached = cache[UserDefaultsKeys.birthDate] as? Date {
            return cached
        }
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.birthDate) as? Date
    }

    /// Returns the user's avatar data if available
    func getAvatarData() async -> Data? {
        if let cached = cache[UserDefaultsKeys.avatarData] as? Data {
            return cached
        }
        return UserDefaults.standard.data(forKey: UserDefaultsKeys.avatarData)
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

        guard let firstName = await getFirstName(),
              let lastName = await getLastName(),
              let birthDate = await getBirthDate() else {
            print("No profile found")
            return nil
        }

        let avatarData = await getAvatarData()
        let userProfileData = UserProfileData(
            firstName: firstName,
            lastName: lastName,
            birthDate: birthDate,
            avatarData: avatarData
        )
        print("Constructed user profile data. Display Name: \(userProfileData.displayName)")
        return userProfileData
    }

    /// Saves user profile data to storage
    /// Updates both cache and UserDefaults
    func setUserProfile(_ profile: UserProfile) async {
        // Update UserDefaults
        UserDefaults.standard.set(profile.firstName, forKey: UserDefaultsKeys.firstName)
        UserDefaults.standard.set(profile.lastName, forKey: UserDefaultsKeys.lastName)
        UserDefaults.standard.set(profile.dateOfBirth, forKey: UserDefaultsKeys.birthDate)
        if let avatarData = profile.avatarData {
            UserDefaults.standard.set(avatarData, forKey: UserDefaultsKeys.avatarData)
        }

        // Update cache
        cache[UserDefaultsKeys.firstName] = profile.firstName
        cache[UserDefaultsKeys.lastName] = profile.lastName
        cache[UserDefaultsKeys.birthDate] = profile.dateOfBirth
        if let avatarData = profile.avatarData {
            cache[UserDefaultsKeys.avatarData] = avatarData
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
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.firstName)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastName)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.birthDate)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.avatarData)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.profileComplete)

        isWarmedUp = false
    }
}

// MARK: - Data Transfer Object

/// Simple data structure representing user profile data from the store
/// Use this when you need to read multiple profile fields at once
struct UserProfileData {
    let firstName: String
    let lastName: String
    let birthDate: Date
    let avatarData: Data?

    var displayName: String {
        "\(firstName) \(lastName)"
    }

    var isAdult: Bool {
        let calendar = Calendar.current
        let birthComponents = calendar.dateComponents([.year], from: birthDate)
        let todayComponents = calendar.dateComponents([.year], from: Date())
        let age = (todayComponents.year ?? 0) - (birthComponents.year ?? 0)
        return age >= 18
    }
}
