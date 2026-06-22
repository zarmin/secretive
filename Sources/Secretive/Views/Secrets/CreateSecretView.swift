import SwiftUI
import SecretKit

struct CreateSecretView<StoreType: SecretStoreModifiable>: View {

    @State var store: StoreType
    @Environment(\.dismiss) private var dismiss
    var createdSecret: (AnySecret?) -> Void

    @State private var name = ""
    @State private var keyAttribution = ""
    @State private var authenticationRequirement: AuthenticationRequirement = .presenceRequired
    @State private var reuseWindow: AuthenticationReuseWindow = .off
    @State private var keyType: KeyType?
    @State var advanced = false
    @State var errorText: String?

    private var authenticationOptions: [AuthenticationRequirement] {
        if advanced || authenticationRequirement == .biometryCurrent {
            [.presenceRequired, .notRequired, .biometryCurrent]
        } else {
            [.presenceRequired, .notRequired]
        }
    }

    var body: some View {
        VStack(alignment: .trailing) {
            Form {
                Section {
                    TextField(String(localized: .createSecretNameLabel), text: $name, prompt: Text(.createSecretNamePlaceholder))
                    VStack(alignment: .leading, spacing: 10) {
                        Picker(.createSecretProtectionLevelTitle, selection: $authenticationRequirement) {
                            ForEach(authenticationOptions) { option in
                                HStack {
                                    switch option {
                                    case .notRequired:
                                        Image(systemName: "bell")
                                        Text(.createSecretNotifyTitle)
                                    case .presenceRequired:
                                        Image(systemName: "lock")
                                        Text(.createSecretRequireAuthenticationTitle)
                                    case .biometryCurrent:
                                        Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                                        Text(.createSecretRequireAuthenticationBiometricCurrentTitle)
                                    case .unknown:
                                        EmptyView()
                                    }
                                }
                                .tag(option)
                            }
                        }
                        Group {
                            switch  authenticationRequirement {
                            case .notRequired:
                                Text(.createSecretNotifyDescription)
                            case .presenceRequired:
                                Text(.createSecretRequireAuthenticationDescription)
                            case .biometryCurrent:
                                Text(.createSecretRequireAuthenticationBiometricCurrentDescription)
                            case .unknown:
                                EmptyView()
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        if authenticationRequirement == .biometryCurrent {
                            Text(.createSecretBiometryCurrentWarning)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .boxBackground(color: .red)
                        }
                        if authenticationRequirement.required {
                            Divider()
                            ReuseWindowPicker(selection: $reuseWindow)
                        }

                    }
                }
                if advanced {
                    Section {
                        VStack {
                            Picker(.createSecretKeyTypeLabel, selection: $keyType) {
                                ForEach(store.supportedKeyTypes.available, id: \.self) { option in
                                    Text(String(describing: option))
                                        .tag(option)
                                }
                                Divider()
                                ForEach(store.supportedKeyTypes.unavailable, id: \.keyType) { option in
                                    VStack {
                                        Button {
                                        } label: {
                                            Text(String(describing: option.keyType))
                                            switch option.reason {
                                            case .macOSUpdateRequired:
                                                Text(.createSecretKeyTypeMacOSUpdateRequiredLabel)
                                            }
                                        }
                                    }
                                    .selectionDisabled()
                                }
                            }
                            if keyType?.algorithm == .mldsa {
                                Text(.createSecretMldsaWarning)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3)
                                    .boxBackground(color: .orange)
                            }
                        }
                        VStack(alignment: .leading) {
                            TextField(.createSecretKeyAttributionLabel, text: $keyAttribution, prompt: Text(verbatim: "test@example.com"))
                            Text(.createSecretKeyAttributionDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                if let errorText {
                    Section {
                    } footer: {
                        Text(verbatim: errorText)
                            .errorStyle()
                    }
                }
            }
            HStack {
                Toggle(.createSecretAdvancedLabel, isOn: $advanced)
                    .toggleStyle(.button)
                Spacer()
                Button(.createSecretCancelButton, role: .cancel) {
                    dismiss()
                }
                Button(.createSecretCreateButton, action: save)
                    .keyboardShortcut(.return)
                    .primaryButton()
                    .disabled(name.isEmpty)
            }
            .padding()
        }
        .onAppear {
            keyType = store.supportedKeyTypes.available.first
        }
        .formStyle(.grouped)
    }

    func save() {
        let attribution = keyAttribution.isEmpty ? nil : keyAttribution
        Task {
            do {
                let new = try await store.create(
                    name: name,
                    attributes: .init(
                        keyType: keyType!,
                        authentication: authenticationRequirement,
                        publicKeyAttribution: attribution,
                        authenticationReuseWindow: authenticationRequirement.required ? reuseWindow : nil
                    )
                )
                createdSecret(AnySecret(new))
                dismiss()
            } catch {
                errorText = error.localizedDescription
            }
        }
    }

}

/// Per-key picker for the authentication reuse window. Shared by the create and edit sheets.
struct ReuseWindowPicker: View {

    @Binding var selection: AuthenticationReuseWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Reauthentication window", selection: $selection) {
                ForEach(AuthenticationReuseWindow.allCases) { window in
                    Text(Self.label(for: window))
                        .tag(window)
                }
            }
            Text("After you authenticate, additional signatures for this key within this window are allowed without prompting again. \"Off\" requires authentication for every signature.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    static func label(for window: AuthenticationReuseWindow) -> String {
        guard window != .off else { return String(localized: "Off") }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.second]
        return formatter.string(from: window.duration) ?? "\(Int(window.duration)) seconds"
    }

}

//#Preview {
//    CreateSecretView(store: Preview.StoreModifiable()) { _ in }
//}
