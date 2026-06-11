import Foundation
import Security

extension ProcessInfo {
    private static let fallbackTeamID = "M46P3U72YT"

    private static let teamID: String = {
        // Provisioned builds carry the team identifier as an entitlement.
        if let task = SecTaskCreateFromSelf(nil),
           let value = SecTaskCopyValueForEntitlement(task, "com.apple.developer.team-identifier" as CFString, nil) as? String {
            return value
        }

        // Unprovisioned builds (local development signing) don't have the
        // entitlement; read the team from the process's own code signature.
        var code: SecCode?
        var staticCode: SecStaticCode?
        var info: CFDictionary?
        if unsafe SecCodeCopySelf([], &code) == errSecSuccess,
           let code,
           unsafe SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess,
           let staticCode,
           unsafe SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
           let value = (info as? [String: Any])?[kSecCodeInfoTeamIdentifier as String] as? String {
            return value
        }

        assertionFailure("Unable to determine team identifier from entitlements or code signature")
        return fallbackTeamID
    }()

    public var teamID: String { Self.teamID }
}
