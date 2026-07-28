import AppKit
import SwiftUI

@main
struct BridgeLockApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject
    private var settings = AppSettings()

    @StateObject
    private var pinStore = PINStore()

    @StateObject
    private var desktopLockController = DesktopLockController()

    var body: some Scene {
        MenuBarExtra {
            MainView()
                .environmentObject(settings)
                .environmentObject(pinStore)
                .environmentObject(desktopLockController)
        } label: {
            Image(
                systemName: desktopLockController.isLocked
                    ? "lock.fill"
                    : "lock.open.fill"
            )
            .accessibilityLabel(
                desktopLockController.isLocked
                    ? "BridgeLock locked"
                    : "BridgeLock unlocked"
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(pinStore)
                .environmentObject(desktopLockController)
        }
        .defaultSize(
            width: 520,
            height: 560
        )
    }
}