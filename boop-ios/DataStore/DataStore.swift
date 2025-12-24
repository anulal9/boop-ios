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
        if let appleUserID = UserDefaults.standard.string(forKey: UserDefaultsKeys.appleUserID) {
            cache[UserDefaultsKeys.appleUserID] = appleUserID
        }
        if let firstName = UserDefaults.standard.string(forKey: UserDefaultsKeys.firstName) {
            cache[UserDefaultsKeys.firstName] = firstName
        }
        if let lastName = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastName) {
            cache[UserDefaultsKeys.lastName] = lastName
        }
        if let userName = UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) {
            cache[UserDefaultsKeys.userName] = userName
        }
        if let birthDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.birthDate) as? Date {
            cache[UserDefaultsKeys.birthDate] = birthDate
        }

        cache[UserDefaultsKeys.profileComplete] = UserDefaults.standard.bool(forKey: UserDefaultsKeys.profileComplete)
        cache[UserDefaultsKeys.isAdult] = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isAdult)

        isWarmedUp = true
    }

    // MARK: - User Profile Accessors

    /// Returns the Apple user ID if available
    func getAppleUserID() async -> String? {
        if let cached = cache[UserDefaultsKeys.appleUserID] as? String {
            return cached
        }
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.appleUserID)
    }

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

    /// Returns the user's username if available
    func getUserName() async -> String? {
        if let cached = cache[UserDefaultsKeys.userName] as? String {
            return cached
        }
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.userName)
    }

    /// Returns the user's birth date if available
    func getBirthDate() async -> Date? {
        if let cached = cache[UserDefaultsKeys.birthDate] as? Date {
            return cached
        }
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.birthDate) as? Date
    }

    /// Returns whether the user's profile setup is complete
    func isProfileComplete() async -> Bool {
        if let cached = cache[UserDefaultsKeys.profileComplete] as? Bool {
            return cached
        }
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.profileComplete)
    }

    /// Returns whether the user is an adult
    func isAdult() async -> Bool {
        if let cached = cache[UserDefaultsKeys.isAdult] as? Bool {
            return cached
        }
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.isAdult)
    }

    // MARK: - Bulk Profile Operations

    /// Returns all available user profile data
    /// Returns nil if no user is signed in (no Apple user ID)
    func getUserProfile() async -> UserProfileData? {
        guard let appleUserID = await getAppleUserID() else {
            return nil
        }

        return UserProfileData(
            appleUserID: appleUserID,
            firstName: await getFirstName(),
            lastName: await getLastName(),
            userName: await getUserName(),
            birthDate: await getBirthDate(),
            isAdult: await isAdult()
        )
    }

    /// Saves user profile data to storage
    /// Updates both cache and UserDefaults
    func setUserProfile(_ profile: UserProfile) async {
        // Update UserDefaults
        UserDefaults.standard.set(profile.appleUserID, forKey: UserDefaultsKeys.appleUserID)
        UserDefaults.standard.set(profile.firstName, forKey: UserDefaultsKeys.firstName)
        UserDefaults.standard.set(profile.lastName, forKey: UserDefaultsKeys.lastName)
        UserDefaults.standard.set(profile.userName, forKey: UserDefaultsKeys.userName)
        UserDefaults.standard.set(profile.dateOfBirth, forKey: UserDefaultsKeys.birthDate)
        UserDefaults.standard.set(profile.isAdult, forKey: UserDefaultsKeys.isAdult)

        // Update cache
        cache[UserDefaultsKeys.appleUserID] = profile.appleUserID
        cache[UserDefaultsKeys.firstName] = profile.firstName
        cache[UserDefaultsKeys.lastName] = profile.lastName
        cache[UserDefaultsKeys.userName] = profile.userName
        cache[UserDefaultsKeys.birthDate] = profile.dateOfBirth
        cache[UserDefaultsKeys.isAdult] = profile.isAdult
    }

    // MARK: - Individual Setters

    /// Sets the Apple user ID
    func setAppleUserID(_ id: String) async {
        UserDefaults.standard.set(id, forKey: UserDefaultsKeys.appleUserID)
        cache[UserDefaultsKeys.appleUserID] = id
    }

    /// Sets the profile completion status
    func setProfileComplete(_ isComplete: Bool) async {
        UserDefaults.standard.set(isComplete, forKey: UserDefaultsKeys.profileComplete)
        cache[UserDefaultsKeys.profileComplete] = isComplete
    }

    // MARK: - Cache Management

    /// Clears all user data from both cache and UserDefaults
    /// Use this when logging out
    func clear() async {
        // Clear cache
        cache.removeAll()

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.appleUserID)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.firstName)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastName)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userName)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.birthDate)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.profileComplete)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.isAdult)

        isWarmedUp = false
    }
}

// MARK: - Data Transfer Object

/// Simple data structure representing user profile data from the store
/// Use this when you need to read multiple profile fields at once
struct UserProfileData {
    let appleUserID: String
    let firstName: String?
    let lastName: String?
    let userName: String?
    let birthDate: Date?
    let isAdult: Bool

    var displayName: String? {
        guard let first = firstName, let last = lastName else {
            return nil
        }
        return "\(first) \(last)"
    }
}
