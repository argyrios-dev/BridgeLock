import AppKit
import CoreGraphics
import Foundation

@MainActor
final class DesktopLockController: ObservableObject {

    @Published
    private(set) var isLocked = false

    @Published
    private(set) var lastErrorMessage: String?

    private let presentationMode = LockPresentationMode()
    private let globalEventTap = GlobalEventTap()

    private var lockWindow: LockWindow?

    func lockCurrentSpace(
        settings: AppSettings,
        pinStore: PINStore
    ) {
        guard !isLocked else {
            return
        }

        lastErrorMessage = nil

        guard pinStore.hasPIN else {
            lastErrorMessage = "A security PIN must be configured before locking a Space."
            return
        }

        guard let screen = targetScreen() else {
            lastErrorMessage = "BridgeLock could not detect the active screen."
            return
        }

        guard globalEventTap.requestAccessibilityPermission() else {
            lastErrorMessage = "Enable BridgeLock in System Settings under Privacy & Security, Accessibility, then try again."
            return
        }

        do {
            try globalEventTap.start()
        } catch {
            lastErrorMessage = error.localizedDescription
            return
        }

        SettingsWindowController.shared.close()

        let isFullScreenSpace = activeSpaceContainsFullScreenWindow(
            on: screen
        )

        let panel = LockWindow(
            screen: screen,
            isFullScreenSpace: isFullScreenSpace,
            settings: settings,
            pinStore: pinStore,
            controller: self
        )

        lockWindow = panel
        isLocked = true

        presentationMode.activate()
        panel.present()
    }

    func unlockCurrentSpace() {
        guard isLocked else {
            return
        }

        globalEventTap.stop()
        presentationMode.restore()

        let panel = lockWindow
        lockWindow = nil

        panel?.orderOut(nil)
        panel?.forceClose()

        isLocked = false
        lastErrorMessage = nil
    }

    func authorizeTermination() {
        TerminationAuthorization.shared.authorize()
    }

    func authorizeTerminationAndQuit() {
        guard !isLocked else {
            lastErrorMessage = "Unlock the protected Space before quitting BridgeLock."
            return
        }

        globalEventTap.stop()
        presentationMode.restore()
        authorizeTermination()
        NSApp.terminate(nil)
    }

    private func targetScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation

        if let cursorScreen = NSScreen.screens.first(
            where: { NSMouseInRect(mouseLocation, $0.frame, false) }
        ) {
            return cursorScreen
        }

        return NSScreen.main ?? NSScreen.screens.first
    }

    private func activeSpaceContainsFullScreenWindow(
        on screen: NSScreen
    ) -> Bool {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }

        let targetFrame = coreGraphicsFrame(for: screen)
        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier

        for windowInfo in windowList {
            guard
                let ownerPIDNumber = windowInfo[
                    kCGWindowOwnerPID as String
                ] as? NSNumber,
                ownerPIDNumber.int32Value != currentProcessIdentifier,
                let layerNumber = windowInfo[
                    kCGWindowLayer as String
                ] as? NSNumber,
                layerNumber.intValue == 0,
                let alphaNumber = windowInfo[
                    kCGWindowAlpha as String
                ] as? NSNumber,
                alphaNumber.doubleValue > 0.01,
                let boundsDictionary = windowInfo[
                    kCGWindowBounds as String
                ] as? NSDictionary
            else {
                continue
            }

            var windowFrame = CGRect.zero

            guard CGRectMakeWithDictionaryRepresentation(
                boundsDictionary,
                &windowFrame
            ) else {
                continue
            }

            let intersection = targetFrame.intersection(windowFrame)

            guard !intersection.isNull, !intersection.isEmpty else {
                continue
            }

            let widthCoverage = intersection.width / targetFrame.width
            let heightCoverage = intersection.height / targetFrame.height

            if widthCoverage >= 0.96 &&
                heightCoverage >= 0.94 {
                return true
            }
        }

        return false
    }

    private func coreGraphicsFrame(
        for screen: NSScreen
    ) -> CGRect {
        let primaryScreen = primaryScreen() ?? NSScreen.screens.first ?? screen

        return CGRect(
            x: screen.frame.minX,
            y: primaryScreen.frame.maxY - screen.frame.maxY,
            width: screen.frame.width,
            height: screen.frame.height
        )
    }

    private func primaryScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber else {
                return false
            }

            return CGDirectDisplayID(
                screenNumber.uint32Value
            ) == CGMainDisplayID()
        }
    }
}