import AppKit

@MainActor
final class LockPresentationMode {

    private var previousOptions: NSApplication.PresentationOptions?
    private(set) var isActive = false

    func activate() {
        guard !isActive else {
            return
        }

        previousOptions = NSApp.presentationOptions

        var options = NSApp.presentationOptions
        options.insert(.autoHideDock)
        options.insert(.autoHideMenuBar)
        options.insert(.disableAppleMenu)
        options.insert(.disableForceQuit)
        options.insert(.disableSessionTermination)
        options.insert(.disableHideApplication)
        options.insert(.disableMenuBarTransparency)

        options.remove(.disableProcessSwitching)

        NSApp.presentationOptions = options
        isActive = true
    }

    func restore() {
        guard isActive else {
            return
        }

        if let previousOptions {
            NSApp.presentationOptions = previousOptions
        }

        previousOptions = nil
        isActive = false
    }
}