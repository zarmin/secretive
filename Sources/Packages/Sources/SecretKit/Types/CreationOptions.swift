import Foundation

public struct Attributes: Sendable, Codable, Hashable {
    
    /// The type of key involved.
    public let keyType: KeyType

    /// The authentication requirements for the key. This is simply a description of the option recorded at creation – modifying it doers not modify the key's authentication requirements.
    public let authentication: AuthenticationRequirement
    
    /// The string appended to the end of the SSH Public Key.
    /// If nil, a default value will be used.
    public var publicKeyAttribution: String?

    /// How long an authentication may be reused before a key that requires authentication prompts again.
    /// If nil, the key is treated as ``AuthenticationReuseWindow/off`` (authenticate on every signature).
    public var authenticationReuseWindow: AuthenticationReuseWindow?

    public init(
        keyType: KeyType,
        authentication: AuthenticationRequirement,
        publicKeyAttribution: String? = nil,
        authenticationReuseWindow: AuthenticationReuseWindow? = nil
    ) {
        self.keyType = keyType
        self.authentication = authentication
        self.publicKeyAttribution = publicKeyAttribution
        self.authenticationReuseWindow = authenticationReuseWindow
    }

    public struct UnsupportedOptionError: Error {
        package init() {}
    }

}

/// How long a successful authentication may be reused for a key that requires authentication, before the user is
/// prompted again. Sized for parallel-ssh / fan-out workloads where one operation triggers many signatures at once.
public enum AuthenticationReuseWindow: String, CaseIterable, Hashable, Sendable, Codable, Identifiable {

    /// Authenticate on every signature (no reuse).
    case off
    case fiveSeconds
    case tenSeconds
    case thirtySeconds

    public var id: AuthenticationReuseWindow { self }

    /// The reuse window in seconds. `0` for ``off``.
    public var duration: TimeInterval {
        switch self {
        case .off: 0
        case .fiveSeconds: 5
        case .tenSeconds: 10
        case .thirtySeconds: 30
        }
    }
}

/// The option specified
public enum AuthenticationRequirement: String, Hashable, Sendable, Codable, Identifiable {

    /// Authentication is not required for usage.
    case notRequired
    
    /// The user needs to authenticate, using either a biometric option, a connected authorized watch, or password entry..
    case presenceRequired
    
    /// ONLY the current set of biometric data, as matching at time of creation, is accepted.
    /// - Warning: This is a dangerous option prone to data loss. The user should be warned before configuring this key that if they modify their enrolled biometry INCLUDING by simply adding a new entry (ie, adding another fingeprting), the key will no longer be able to be accessed. This cannot be overridden with a password.
    case biometryCurrent
    
    /// The authentication requirement was not recorded at creation, and is unknown.
    case unknown
    
    /// Whether or not the key is known to require authentication.
    public var required: Bool {
        self == .presenceRequired || self == .biometryCurrent
    }

    public var id: AuthenticationRequirement {
        self
    }
}
