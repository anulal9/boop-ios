import Foundation

/// Coordinates async storage initialization to prevent race conditions
/// between directory creation and UserDefaults/SwiftData access
actor StorageCoordinator {
    static let shared = StorageCoordinator()

    private var isInitialized = false
    private var initializationTask: Task<Void, Error>?
    private var waitingContinuations: [CheckedContinuation<Void, Error>] = []

    private init() {}

    /// Starts the async directory initialization process with the given ModelConfiguration URL
    /// Safe to call multiple times with same URL - will only initialize once
    /// All I/O happens asynchronously in the background
    /// - Parameter configurationURL: The URL from ModelConfiguration.url
    func initialize(with configurationURL: URL) {
        guard initializationTask == nil else { return }

        initializationTask = Task {
            do {
                // Check if directory exists and create if needed 
                try await createStorageDirectory(for: configurationURL)

                // Mark as complete
                await markInitialized()
            } catch {
                await markFailed(error: error)
                throw error
            }
        }
    }

    /// Wait for storage initialization to complete
    /// Returns immediately if already initialized
    /// Note: initialize(with:) must be called before this method
    func waitForInitialization() async throws {
        // If already initialized, return immediately
        if isInitialized {
            return
        }

        // If initialization hasn't started, something is wrong
        guard initializationTask != nil else {
            throw StorageCoordinatorError.initializationNotStarted
        }

        // Wait for completion using continuation
        try await withCheckedThrowingContinuation { continuation in
            if isInitialized {
                continuation.resume()
            } else {
                waitingContinuations.append(continuation)
            }
        }
    }

    enum StorageCoordinatorError: Error {
        case initializationNotStarted
    }

    private func createStorageDirectory(for configurationURL: URL) async throws {
        try await Task.detached(priority: .high) {
            // The configurationURL points to the store file itself
            // We need to ensure its parent directory exists
            let directory = configurationURL.deletingLastPathComponent()

            // Check if directory already exists (common case after first app launch)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                // Directory already exists - nothing to do
                return
            }

            // Directory doesn't exist - create it
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch CocoaError.fileWriteFileExists {
                // Directory was created between our check and creation - this is fine
                return
            }
            // Other errors are re-thrown
        }.value
    }

    private func markInitialized() async {
        print("successfully created directory")
        isInitialized = true
        // Resume all waiting continuations
        waitingContinuations.forEach { $0.resume() }
        waitingContinuations.removeAll()
    }

    private func markFailed(error: Error) async {
        // Resume all waiting continuations with error
        print("failed to create directory: \(error.localizedDescription)")
        waitingContinuations.forEach { $0.resume(throwing: error) }
        waitingContinuations.removeAll()
    }
}
