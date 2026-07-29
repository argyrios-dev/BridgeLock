import SwiftUI

struct LockView: View {

    @EnvironmentObject
    private var settings: AppSettings

    @EnvironmentObject
    private var pinStore: PINStore

    @EnvironmentObject
    private var controller: DesktopLockController

    let isFullScreenSpace: Bool

    @State
    private var pin = ""

    @State
    private var errorMessage: String?

    @State
    private var isAuthenticatingBiometrics = false

    @FocusState
    private var isPINFieldFocused: Bool

    var body: some View {
        ZStack {
            LockBackgroundView(
                forceOpaque: false
            )

            VStack(spacing: 0) {
                if isFullScreenSpace {
                    fullScreenBanner
                        .padding(.top, 28)
                }

                Spacer()

                contentCard

                Spacer()
            }
            .padding(40)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .ignoresSafeArea()
        .onAppear {
            // Solo enfocamos el PIN (no lanzamos Touch ID automáticamente)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPINFieldFocused = true
            }
        }
    }
}

private extension LockView {

    var fullScreenBanner: some View {
        Text("BridgeLock is protecting this full-screen Space")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.white.opacity(0.12))
            .clipShape(Capsule())
    }

    var contentCard: some View {
        VStack(spacing: 22) {
            Image(systemName: "lock.fill")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.white)

            Text(
                isFullScreenSpace
                    ? "Full-Screen Space Locked"
                    : "Space Locked"
            )
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(.white)

            Text("Protected by BridgeLock")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))

            // ——— PIN (principal) ———
            SecureField("PIN", text: $pin)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)
                .focused($isPINFieldFocused)
                .onChange(of: pin) { newValue in
                    pin = filteredPIN(newValue)
                    errorMessage = nil
                }
                .onSubmit {
                    unlockWithPIN()
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Button("Unlock Space") {
                unlockWithPIN()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(width: 180)

            // ——— Touch ID (opción secundaria) ———
            if BiometricAuthenticator.canEvaluate {
                Button {
                    Task {
                        await unlockWithBiometrics()
                    }
                } label: {
                    Label(
                        "Unlock with \(BiometricAuthenticator.biometryTypeName)",
                        systemImage: "touchid"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isAuthenticatingBiometrics)
            }
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 40)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(.black.opacity(isFullScreenSpace ? 0.38 : 0.75))
        }
    }

    func filteredPIN(_ value: String) -> String {
        String(
            value
                .filter { $0.isASCII && $0.isNumber }
                .prefix(12)
        )
    }

    func unlockWithPIN() {
        guard pinStore.verify(pin: pin) else {
            pin = ""
            errorMessage = "Incorrect PIN."
            isPINFieldFocused = true
            return
        }

        errorMessage = nil
        pin = ""
        controller.unlockCurrentSpace()
    }

    @MainActor
    func unlockWithBiometrics() async {
        guard !isAuthenticatingBiometrics else { return }

        isAuthenticatingBiometrics = true
        errorMessage = nil

        let result = await BiometricAuthenticator.authenticate(
            reason: "Unlock the protected Space with \(BiometricAuthenticator.biometryTypeName)"
        )

        isAuthenticatingBiometrics = false

        switch result {
        case .success:
            pin = ""
            errorMessage = nil
            controller.unlockCurrentSpace()

        case .failure(let error):
            if error != .cancelled, let message = error.errorDescription {
                errorMessage = message
            }
            // Volvemos el foco al PIN
            isPINFieldFocused = true
        }
    }
}