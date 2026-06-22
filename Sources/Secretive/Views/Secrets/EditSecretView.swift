import SwiftUI
import SecretKit

struct EditSecretView<StoreType: SecretStoreModifiable>: View {

    let store: StoreType
    let secret: StoreType.SecretType

    @State private var name: String
    @State private var publicKeyAttribution: String
    @State private var reuseWindow: AuthenticationReuseWindow
    @State var errorText: String?

    @Environment(\.dismiss) var dismiss

    init(store: StoreType, secret: StoreType.SecretType) {
        self.store = store
        self.secret = secret
        name = secret.name
        publicKeyAttribution = secret.publicKeyAttribution ?? ""
        reuseWindow = secret.reuseWindow
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Form {
                Section {
                    TextField(String(localized: .createSecretNameLabel), text: $name, prompt: Text(.createSecretNamePlaceholder))
                    VStack(alignment: .leading) {
                        TextField(.createSecretKeyAttributionLabel, text: $publicKeyAttribution, prompt: Text(verbatim: "test@example.com"))
                        Text(.createSecretKeyAttributionDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if secret.authenticationRequirement.required {
                        ReuseWindowPicker(selection: $reuseWindow)
                    }
                } footer: {
                    if let errorText {
                        Text(verbatim: errorText)
                            .errorStyle()
                    }
                }
            }
            HStack {
                Button(.editCancelButton) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button(.editSaveButton, action: rename)
                    .disabled(name.isEmpty)
                    .keyboardShortcut(.return)
                    .primaryButton()
            }
            .padding()
        }
        .formStyle(.grouped)
    }

    func rename() {
        var attributes = secret.attributes
        attributes.publicKeyAttribution = publicKeyAttribution.isEmpty ? nil : publicKeyAttribution
        attributes.authenticationReuseWindow = secret.authenticationRequirement.required ? reuseWindow : nil
        Task {
            do {
                try await store.update(secret: secret, name: name, attributes: attributes)
                dismiss()
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
