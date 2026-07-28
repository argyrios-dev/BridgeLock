import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if TerminationAuthorization.shared.consumeAuthorization() {
            return .terminateNow
        }

        guard PINStore.hasStoredPIN else {
            return .terminateNow
        }

        return .terminateCancel
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}

@MainActor
final class TerminationAuthorization {
    static let shared = TerminationAuthorization()

    private var isAuthorized = false

    private init() {}

    func authorize() {
        isAuthorized = true
    }

    func revoke() {
        isAuthorized = false
    }

    func consumeAuthorization() -> Bool {
        guard isAuthorized else {
            return false
        }

        isAuthorized = false
        return true
    }
}