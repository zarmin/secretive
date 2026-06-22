import Foundation
import Testing
@testable import SecretKit
@testable import SmartCardSecretKit

@Suite struct AuthenticationReuseWindowTests {

    private func secret(window: AuthenticationReuseWindow?) -> SmartCard.Secret {
        let data = Data(UUID().uuidString.utf8)
        return SmartCard.Secret(
            id: data,
            name: "Name",
            publicKey: data,
            attributes: Attributes(keyType: .ecdsa256, authentication: .presenceRequired, authenticationReuseWindow: window)
        )
    }

    @Test func durations() {
        #expect(AuthenticationReuseWindow.off.duration == 0)
        #expect(AuthenticationReuseWindow.fiveSeconds.duration == 5)
        #expect(AuthenticationReuseWindow.tenSeconds.duration == 10)
        #expect(AuthenticationReuseWindow.thirtySeconds.duration == 30)
    }

    @Test func nilWindowIsOff() {
        #expect(secret(window: nil).reuseWindow == .off)
    }

    @Test func roundTripsThroughJSON() throws {
        for window in AuthenticationReuseWindow.allCases {
            let attributes = Attributes(keyType: .ecdsa256, authentication: .presenceRequired, authenticationReuseWindow: window)
            let encoded = try JSONEncoder().encode(attributes)
            let decoded = try JSONDecoder().decode(Attributes.self, from: encoded)
            #expect(decoded.authenticationReuseWindow == window)
        }
    }

    /// Attributes written before this setting existed have no window key (Swift omits nil optionals),
    /// so that JSON must decode back as `nil` (== off).
    @Test func legacyAttributesWithoutWindowDecodeToOff() throws {
        let legacy = Attributes(keyType: .ecdsa256, authentication: .presenceRequired, authenticationReuseWindow: nil)
        let encoded = try JSONEncoder().encode(legacy)
        #expect(!String(decoding: encoded, as: UTF8.self).contains("authenticationReuseWindow"))
        let decoded = try JSONDecoder().decode(Attributes.self, from: encoded)
        #expect(decoded.authenticationReuseWindow == nil)
    }

}
