import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject {

    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    func show(
        settings: AppSettings,
        pinStore: PINStore,
        controller: DesktopLockController
    ) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = SettingsView()
            .environmentObject(settings)
            .environmentObject(pinStore)
            .environmentObject(controller)

        let hostingController = NSHostingController(
            rootView: rootView
        )

        let window = NSWindow(
            contentViewController: hostingController
        )

        window.title = "BridgeLock Settings"
        window.setContentSize(
            NSSize(width: 540, height: 600)
        )

        window.styleMask = [
            .titled,
            .closable,
            .miniaturizable
        ]

        window.isReleasedWhenClosed = false
        window.center()

        window.delegate = self

        self.window = window

        window.makeKeyAndOrderFront(nil)

        NSApp.activate(
            ignoringOtherApps: true
        )
    }

    func close() {
        window?.close()
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }
}

extension SettingsWindowController: NSWindowDelegate {

    func windowWillClose(
        _ notification: Notification
    ) {
        window = nil
    }
}