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
    }

    override func performClose(_ sender: Any?) {
    }

    override func close() {
    }

    override func miniaturize(_ sender: Any?) {
    }

    override func zoom(_ sender: Any?) {
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

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            NSApp.activate(ignoringOtherApps: true)
            self.makeKey()
            self.makeMain()
            self.orderFrontRegardless()
        }
    }
}