import Foundation

extension String {
    /// Trims whitespace from both ends of the string
    func trimWhitespace() -> String {
        self.trimmingCharacters(in: .whitespaces)
    }

    /// Trims newlines from both ends of the string
    func trimNewlines() -> String {
        self.trimmingCharacters(in: .newlines)
    }

    /// Trims both whitespace and newlines from both ends of the string
    func trimWhitespaceAndNewlines() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func sanitize() -> String {
        self.trimWhitespaceAndNewlines()
    }

    /// Returns true if the string is empty after trimming whitespace and newlines
    var isEmptyAfterSanitizing: Bool {
        self.trimWhitespaceAndNewlines().isEmpty
    }
}
