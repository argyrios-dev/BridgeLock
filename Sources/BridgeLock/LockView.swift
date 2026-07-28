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

    var body: some View {
        ZStack {
            LockBackgroundView(
                forceOpaque: !isFullScreenSpace
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

            SecureField("PIN", text: $pin)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)
                .onChange(of: pin) { newValue in
                    pin = filteredPIN(newValue)
                    errorMessage = nil
                }
                .onSubmit {
                    unlock()
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Button("Unlock Space") {
                unlock()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(width: 180)
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

    func unlock() {
        guard pinStore.verify(pin: pin) else {
            pin = ""
            errorMessage = "Incorrect PIN."
            return
        }

        errorMessage = nil
        pin = ""

        controller.unlockCurrentSpace()
    }
}