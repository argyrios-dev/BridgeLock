@preconcurrency import ApplicationServices
@preconcurrency import CoreGraphics
import Foundation

final class GlobalEventTap {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private var isFilteringEnabled = false

    var isRunning: Bool {
        eventTap != nil
    }

    func requestAccessibilityPermission() -> Bool {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString

        let options = [
            promptKey: true as CFBoolean
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    func setFilteringEnabled(_ enabled: Bool) {
        isFilteringEnabled = enabled
    }

    func start() throws {
        guard eventTap == nil else {
            return
        }

        guard AXIsProcessTrusted() else {
            throw GlobalEventTapError.accessibilityPermissionRequired
        }

        let eventMask =
            mask(for: .keyDown) |
            mask(for: .scrollWheel) |
            mask(for: .leftMouseDown) |
            mask(for: .leftMouseUp) |
            mask(for: .rightMouseDown) |
            mask(for: .rightMouseUp) |
            mask(for: .rightMouseDragged) |
            mask(for: .otherMouseDown) |
            mask(for: .otherMouseUp) |
            mask(for: .otherMouseDragged) |
            mask(for: .tapDisabledByTimeout) |
            mask(for: .tapDisabledByUserInput)

        let userInfo = Unmanaged
            .passUnretained(self)
            .toOpaque()

        guard let createdEventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: bridgeLockEventTapCallback,
            userInfo: userInfo
        ) else {
            throw GlobalEventTapError.couldNotCreateEventTap
        }

        guard let createdRunLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            createdEventTap,
            0
        ) else {
            CFMachPortInvalidate(createdEventTap)
            throw GlobalEventTapError.couldNotCreateRunLoopSource
        }

        eventTap = createdEventTap
        runLoopSource = createdRunLoopSource

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            createdRunLoopSource,
            .commonModes
        )

        CGEvent.tapEnable(
            tap: createdEventTap,
            enable: true
        )
    }

    func stop() {
        isFilteringEnabled = false

        if let eventTap {
            CGEvent.tapEnable(
                tap: eventTap,
                enable: false
            )
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                runLoopSource,
                .commonModes
            )
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }

        runLoopSource = nil
        eventTap = nil
    }

    fileprivate func handle(
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout,
             .tapDisabledByUserInput:
            reenableEventTap()
            return Unmanaged.passUnretained(event)

        default:
            break
        }

        guard isFilteringEnabled else {
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .keyDown:
            return handleKeyDown(event)

        case .scrollWheel:
            return handleScrollWheel(event)

        case .rightMouseDown,
             .rightMouseUp,
             .rightMouseDragged,
             .otherMouseDown,
             .otherMouseUp,
             .otherMouseDragged:
            return nil

        case .leftMouseDown,
             .leftMouseUp:
            return handleLeftMouseEvent(event)

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func handleKeyDown(
        _ event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        let keyCode = CGKeyCode(
            event.getIntegerValueField(
                .keyboardEventKeycode
            )
        )

        let flags = event.flags

        if isMissionControlFunctionKey(keyCode) {
            return nil
        }

        if flags.contains(.maskControl) {
            switch keyCode {
            case KeyCode.upArrow,
                 KeyCode.downArrow:
                return nil

            case KeyCode.leftArrow,
                 KeyCode.rightArrow:
                return Unmanaged.passUnretained(event)

            default:
                break
            }
        }

        if flags.contains(.maskCommand) {
            switch keyCode {
            case KeyCode.tab,
                 KeyCode.grave:
                return nil

            default:
                break
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func handleLeftMouseEvent(
        _ event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if event.flags.contains(.maskControl) {
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func handleScrollWheel(
        _ event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        let isContinuous = event.getIntegerValueField(
            .scrollWheelEventIsContinuous
        ) != 0

        guard isContinuous else {
            return Unmanaged.passUnretained(event)
        }

        let verticalDelta = largestMagnitude(
            event.getDoubleValueField(
                .scrollWheelEventPointDeltaAxis1
            ),
            event.getDoubleValueField(
                .scrollWheelEventFixedPtDeltaAxis1
            ),
            Double(
                event.getIntegerValueField(
                    .scrollWheelEventDeltaAxis1
                )
            )
        )

        let horizontalDelta = largestMagnitude(
            event.getDoubleValueField(
                .scrollWheelEventPointDeltaAxis2
            ),
            event.getDoubleValueField(
                .scrollWheelEventFixedPtDeltaAxis2
            ),
            Double(
                event.getIntegerValueField(
                    .scrollWheelEventDeltaAxis2
                )
            )
        )

        guard verticalDelta > 0 || horizontalDelta > 0 else {
            return Unmanaged.passUnretained(event)
        }

        /*
         Horizontal trackpad gestures remain available so the user can
         switch to another Space. Vertical gestures are discarded to
         prevent Mission Control and App Exposé on the protected Space.
         */
        let isHorizontalGesture =
            horizontalDelta > verticalDelta * 1.10

        if isHorizontalGesture {
            return Unmanaged.passUnretained(event)
        }

        return nil
    }

    private func isMissionControlFunctionKey(
        _ keyCode: CGKeyCode
    ) -> Bool {
        switch keyCode {
        case KeyCode.f3,
             KeyCode.missionControl:
            return true

        default:
            return false
        }
    }

    private func largestMagnitude(
        _ first: Double,
        _ second: Double,
        _ third: Double
    ) -> Double {
        max(
            abs(first),
            abs(second),
            abs(third)
        )
    }

    private func reenableEventTap() {
        guard let eventTap else {
            return
        }

        CGEvent.tapEnable(
            tap: eventTap,
            enable: true
        )
    }

    private func mask(
        for eventType: CGEventType
    ) -> CGEventMask {
        CGEventMask(1) << CGEventMask(eventType.rawValue)
    }

    deinit {
        stop()
    }
}

private let bridgeLockEventTapCallback: CGEventTapCallBack = {
    _,
    type,
    event,
    userInfo
in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let eventTap = Unmanaged<GlobalEventTap>
        .fromOpaque(userInfo)
        .takeUnretainedValue()

    return eventTap.handle(
        type: type,
        event: event
    )
}

private enum KeyCode {

    static let tab: CGKeyCode = 48
    static let grave: CGKeyCode = 50

    static let f3: CGKeyCode = 99
    static let missionControl: CGKeyCode = 160

    static let leftArrow: CGKeyCode = 123
    static let rightArrow: CGKeyCode = 124
    static let downArrow: CGKeyCode = 125
    static let upArrow: CGKeyCode = 126
}

enum GlobalEventTapError: LocalizedError {

    case accessibilityPermissionRequired
    case couldNotCreateEventTap
    case couldNotCreateRunLoopSource

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            return "Accessibility permission is required to protect the locked Space."

        case .couldNotCreateEventTap:
            return "BridgeLock could not create the global event tap."

        case .couldNotCreateRunLoopSource:
            return "BridgeLock could not create the event tap run loop source."
        }
    }
}