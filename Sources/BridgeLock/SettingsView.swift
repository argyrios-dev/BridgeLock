import SwiftUI

@MainActor
struct SettingsView: View {

    @EnvironmentObject
    private var settings: AppSettings

    @EnvironmentObject
    private var pinStore: PINStore

    @EnvironmentObject
    private var desktopLockController: DesktopLockController

    @StateObject
    private var loginItemManager = LoginItemManager()

    @State
    private var currentPIN = ""

    @State
    private var newPIN = ""

    @State
    private var repeatedNewPIN = ""

    @State
    private var securityMessage: String?

    @State
    private var securityMessageIsError = false

    @State
    private var isChangingPIN = false

    var body: some View {
        Form {
            startupSection
            securitySection
            applicationSection
        }
        .formStyle(.grouped)
        .frame(
            minWidth: 480,
            idealWidth: 520,
            minHeight: 430,
            idealHeight: 500
        )
        .padding()
    }
}

private extension SettingsView {

    var startupSection: some View {
        Section("Startup") {
            Toggle(
                "Open BridgeLock at login",
                isOn: Binding(
                    get: {
                        loginItemManager.isEnabled
                    },
                    set: { enabled in
                        Task { @MainActor in
                            await loginItemManager.setEnabled(enabled)
                        }
                    }
                )
            )

            Text(loginItemManager.statusDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    var securitySection: some View {
        Section("Security PIN") {
            if pinStore.hasPIN {
                SecureField(
                    "Current PIN",
                    text: $currentPIN
                )
                .textFieldStyle(.roundedBorder)
                .onChange(of: currentPIN) { value in
                    currentPIN = filteredPIN(value)
                    clearSecurityMessage()
                }

                SecureField(
                    "New PIN",
                    text: $newPIN
                )
                .textFieldStyle(.roundedBorder)
                .onChange(of: newPIN) { value in
                    newPIN = filteredPIN(value)
                    clearSecurityMessage()
                }

                SecureField(
                    "Repeat new PIN",
                    text: $repeatedNewPIN
                )
                .textFieldStyle(.roundedBorder)
                .onChange(of: repeatedNewPIN) { value in
                    repeatedNewPIN = filteredPIN(value)
                    clearSecurityMessage()
                }
                .onSubmit {
                    changePIN()
                }

                if let securityMessage {
                    Text(securityMessage)
                        .font(.footnote)
                        .foregroundStyle(
                            securityMessageIsError
                                ? Color.red
                                : Color.green
                        )
                }

                HStack {
                    Spacer()

                    Button("Change PIN") {
                        changePIN()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canChangePIN || isChangingPIN)
                }
            } else {
                Label(
                    "No security PIN is configured.",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(.orange)

                Text(
                    "Create a PIN from the BridgeLock menu before locking a Space."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    var applicationSection: some View {
        Section("Application") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BridgeLock status")
                        .font(.body)

                    Text(
                        desktopLockController.isLocked
                            ? "A Space is currently locked."
                            : "No Space is currently locked."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(
                    systemName: desktopLockController.isLocked
                        ? "lock.fill"
                        : "lock.open.fill"
                )
                .foregroundStyle(
                    desktopLockController.isLocked
                        ? Color.orange
                        : Color.secondary
                )
            }

            Button("Quit BridgeLock") {
                desktopLockController.authorizeTerminationAndQuit()
            }
            .disabled(desktopLockController.isLocked)
        }
    }

    var canChangePIN: Bool {
        guard pinStore.hasPIN else {
            return false
        }

        guard (4...12).contains(currentPIN.count) else {
            return false
        }

        guard (4...12).contains(newPIN.count) else {
            return false
        }

        guard newPIN == repeatedNewPIN else {
            return false
        }

        guard currentPIN != newPIN else {
            return false
        }

        return true
    }

    func changePIN() {
        guard !isChangingPIN else {
            return
        }

        clearSecurityMessage()

        guard (4...12).contains(currentPIN.count) else {
            showSecurityError(
                "Current PIN must contain 4 to 12 digits."
            )
            return
        }

        guard pinStore.verify(pin: currentPIN) else {
            currentPIN = ""
            showSecurityError("Current PIN is incorrect.")
            return
        }

        guard (4...12).contains(newPIN.count) else {
            showSecurityError(
                "New PIN must contain 4 to 12 digits."
            )
            return
        }

        guard newPIN == repeatedNewPIN else {
            repeatedNewPIN = ""
            showSecurityError("New PIN values do not match.")
            return
        }

        guard currentPIN != newPIN else {
            showSecurityError(
                "New PIN must be different from the current PIN."
            )
            return
        }

        isChangingPIN = true

        defer {
            isChangingPIN = false
        }

        do {
            try pinStore.saveNewPIN(newPIN)

            currentPIN = ""
            newPIN = ""
            repeatedNewPIN = ""

            securityMessageIsError = false
            securityMessage = "PIN changed successfully."
        } catch {
            showSecurityError(error.localizedDescription)
        }
    }

    func filteredPIN(_ value: String) -> String {
        String(
            value
                .filter { character in
                    character.isASCII && character.isNumber
                }
                .prefix(12)
        )
    }

    func clearSecurityMessage() {
        securityMessage = nil
        securityMessageIsError = false
    }

    func showSecurityError(_ message: String) {
        securityMessageIsError = true
        securityMessage = message
    }
}