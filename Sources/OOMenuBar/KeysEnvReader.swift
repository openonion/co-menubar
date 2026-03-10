import Foundation

/// Reads agent configuration from ~/.co/keys.env
///
/// The keys.env file contains agent credentials and configuration:
/// - AGENT_ADDRESS: Ed25519 public key (used for chat URL)
/// - OPENONION_API_KEY: JWT token for API access
/// - AGENT_EMAIL: Email address derived from agent address
///
/// ## Usage
/// ```swift
/// if let address = KeysEnvReader.readAgentAddress() {
///     let chatURL = "https://chat.openonion.ai/\(address)"
/// }
/// ```
class KeysEnvReader {
    /// Path to keys.env file
    private static let keysEnvPath = NSHomeDirectory() + "/.co/keys.env"

    /// Read agent address from keys.env
    ///
    /// Parses the `AGENT_ADDRESS=` line from ~/.co/keys.env
    ///
    /// - Returns: Agent address (e.g., "0xcd92510bb6cc090374...") or nil if not found
    static func readAgentAddress() -> String? {
        guard let content = try? String(contentsOfFile: keysEnvPath, encoding: .utf8) else {
            return nil
        }

        // Parse AGENT_ADDRESS=... line
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Look for AGENT_ADDRESS=...
            if trimmed.hasPrefix("AGENT_ADDRESS=") {
                let address = trimmed.replacingOccurrences(of: "AGENT_ADDRESS=", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return address.isEmpty ? nil : address
            }
        }

        return nil
    }

    /// Construct chat URL from agent address
    ///
    /// - Parameter address: Agent address (e.g., "0xcd92510bb6cc090374...")
    /// - Returns: Full chat URL (e.g., "https://chat.openonion.ai/0xcd92510...")
    static func chatURL(for address: String) -> String {
        return "https://chat.openonion.ai/\(address)"
    }

    /// Read agent address and construct chat URL
    ///
    /// Convenience method that combines reading the address and constructing the URL.
    ///
    /// - Returns: Chat URL or nil if agent address not found
    static func readChatURL() -> String? {
        guard let address = readAgentAddress() else {
            return nil
        }
        return chatURL(for: address)
    }
}
