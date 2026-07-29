import AppKit
import SwiftUI

@MainActor
final class LockWindow: NSPanel {

    init(
        screen: NSScreen,
        isFullScreenSpace: Bool,
        settings: AppSettings,
        pinStore: PINStore,
        controller: DesktopLockController
    ) {
        let screenFrame = screen.frame

        super.init(
            contentRect: screenFrame,
            styleMask: [
                .borderless,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        isReleasedWhenClosed = false
        canHide = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false
        hasShadow = false
        acceptsMouseMovedEvents = true

        level = .screenSaver
        animationBehavior = .none

        titleVisibility = .hidden
        titlebarAppearsTransparent = true

        collectionBehavior = [
            .fullScreenAuxiliary,
            .moveToActiveSpace,
            .stationary,
            .ignoresCycle
        ]

        if isFullScreenSpace {
            isOpaque = false
            backgroundColor = .clear
        } else {
            isOpaque = true
            backgroundColor = .black
        }

        let rootView = AnyView(
            LockView(
                isFullScreenSpace: isFullScreenSpace
            )
            .environmentObject(settings)
            .environmentObject(pinStore)
            .environmentObject(controller)
            .frame(
                width: screenFrame.width,
                height: screenFrame.height
            )
            .ignoresSafeArea()
        )

        let hostingController = NSHostingController(
            rootView: rootView
        )

        hostingController.view.frame = NSRect(
            origin: .zero,
            size: screenFrame.size
        )

        hostingController.view.autoresizingMask = [
            .width,
            .height
        ]

        contentViewController = hostingController

        setFrame(
            screenFrame,
            display: true
        )
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func cancelOperation(_ sender: Any?) {
        // Prevent Esc from closing the lock
    }

    override func performClose(_ sender: Any?) {
        // Intentionally empty
    }

    override func close() {
        // Intentionally empty – only forceClose() is allowed
    }

    override func miniaturize(_ sender: Any?) {
        // Intentionally empty
    }

    override func zoom(_ sender: Any?) {
        // Intentionally empty
    }

    override func becomeKey() {
        super.becomeKey()
        orderFrontRegardless()

        // Force first responder after becoming key
        DispatchQueue.main.async { [weak self] in
            guard let self, let contentView = self.contentView else { return }
            if let secureField = self.findSecureTextField(in: contentView) {
                self.makeFirstResponder(secureField)
            }
        }
    }

    func forceClose() {
        super.close()
    }

    func present() {
        if let screen {
            setFrame(
                screen.frame,
                display: true
            )
        }

        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        orderFrontRegardless()

        // First pass right after presentation
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.makeKey()
            self.makeMain()
            self.orderFrontRegardless()
        }

        // Second pass after typical Space transition timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self else { return }
            self.makeKey()
            self.orderFrontRegardless()
            if let contentView = self.contentView,
               let secureField = self.findSecureTextField(in: contentView) {
                self.makeFirstResponder(secureField)
            }
        }

        // Final safety pass
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
            guard let self else { return }
            self.makeKey()
            if let contentView = self.contentView,
               let secureField = self.findSecureTextField(in: contentView) {
                self.makeFirstResponder(secureField)
            }
        }
    }

    // MARK: - Helpers

    private func findSecureTextField(in view: NSView) -> NSSecureTextField? {
        if let field = view as? NSSecureTextField {
            return field
        }
        for subview in view.subviews {
            if let found = findSecureTextField(in: subview) {
                return found
            }
        }
        return nil
    }
}