import AppKit
import SwiftUI

struct LockBackgroundView: View {

    @EnvironmentObject
    private var settings: AppSettings

    let forceOpaque: Bool

    var body: some View {
        Group {
            if forceOpaque || settings.appearance == .black {
                Color.black
            } else {
                VisualEffectBackground()
                    .overlay {
                        Color.black.opacity(0.45)
                    }
            }
        }
        .ignoresSafeArea()
    }
}

private struct VisualEffectBackground: NSViewRepresentable {

    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = .fullScreenUI
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        return effectView
    }

    func updateNSView(
        _ nsView: NSVisualEffectView,
        context: Context
    ) {
        nsView.material = .fullScreenUI
        nsView.blendingMode = .behindWindow
        nsView.state = .active
    }
}