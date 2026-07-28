import SwiftUI

struct MainView: View {

    @EnvironmentObject
    private var settings: AppSettings

    @EnvironmentObject
    private var pinStore: PINStore

    @EnvironmentObject
    private var desktopLockController: DesktopLockController

    @State
    private var setupPIN = ""

    @State
    private var setupRepeatPIN = ""

    @State
    private var quitPIN = ""

    @State
    private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Group {
                if pinStore.hasPIN {
                    configuredContent
                } else {
                    initialPINContent
                }
            }
            .padding(16)

            Divider()

            settingsButton
                .padding(12)
        }
        .frame(width: 320)
    }
}

private extension MainView {

    var header: some View {
        HStack(spacing: 10) {
            Image(systemName: desktopLockController.isLocked ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 18, weight: .semibold))

            Text("BridgeLock")
                .font(.headline)

            Spacer()
        }
        .padding(16)
    }

    var initialPINContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Create Security PIN")
                .font(.headline)

            SecureField(
                "Enter a 4–12 digit PIN",
                text: $setupPIN
            )
            .textFieldStyle(.roundedBorder)
            .onChange(of: setupPIN) { newValue in
                setupPIN = filteredPIN(newValue)
                errorMessage = nil
            }
            .onSubmit {
                savePIN()
            }

            SecureField(
                "Repeat PIN",
                text: $setupRepeatPIN
            )
            .textFieldStyle(.roundedBorder)
            .onChange(of: setupRepeatPIN) { newValue in
                setupRepeatPIN = filteredPIN(newValue)
                errorMessage = nil
            }
            .onSubmit {
                savePIN()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button("Save PIN") {
                savePIN()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(!canSaveInitialPIN)
        }
    }

    var configuredContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                desktopLockController.lockCurrentSpace(
                    settings: settings,
                    pinStore: pinStore
                )
            } label: {
                Label(
                    desktopLockController.isLocked
                        ? "Space Locked"
                        : "Lock Current Space",
                    systemImage: desktopLockController.isLocked
                        ? "lock.fill"
                        : "lock"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(desktopLockController.isLocked)

            Divider()

            SecureField(
                "Enter PIN to quit",
                text: $quitPIN
            )
            .textFieldStyle(.roundedBorder)
            .onChange(of: quitPIN) { newValue in
                quitPIN = filteredPIN(newValue)
                errorMessage = nil
            }
            .onSubmit {
                quitApplication()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button("Verify PIN and Quit") {
                quitApplication()
            }
            .frame(maxWidth: .infinity)
            .disabled(quitPIN.isEmpty)
        }
    }

    var settingsButton: some View {
        Button {
            SettingsWindowController.shared.show(
                settings: settings,
                pinStore: pinStore,
                controller: desktopLockController
            )
        } label: {
            Label("Settings…", systemImage: "gearshape")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    var canSaveInitialPIN: Bool {
        (4...12).contains(setupPIN.count) &&
        setupPIN == setupRepeatPIN
    }

    func filteredPIN(_ value: String) -> String {
        String(
            value
                .filter { $0.isASCII && $0.isNumber }
                .prefix(12)
        )
    }

    func savePIN() {
        errorMessage = nil

        guard (4...12).contains(setupPIN.count) else {
            errorMessage = "PIN must contain 4 to 12 digits."
            return
        }

        guard setupPIN == setupRepeatPIN else {
            errorMessage = "PIN values do not match."
            return
        }

        do {
            try pinStore.saveNewPIN(setupPIN)

            setupPIN = ""
            setupRepeatPIN = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func quitApplication() {
        guard pinStore.verify(pin: quitPIN) else {
            quitPIN = ""
            errorMessage = "Incorrect PIN."
            return
        }

        quitPIN = ""
        errorMessage = nil

        desktopLockController.authorizeTerminationAndQuit()
    }
}