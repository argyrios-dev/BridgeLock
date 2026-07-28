import SwiftUI

@MainActor
final class AppSettings: ObservableObject {

    enum Appearance: String, CaseIterable, Identifiable, Codable {
        case black
        case translucent

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .black:
                return "Black"
            case .translucent:
                return "Translucent"
            }
        }
    }

    private enum Keys {
        static let appearance = "appearance"
    }

    @Published
    var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(
                appearance.rawValue,
                forKey: Keys.appearance
            )
        }
    }

    init() {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.appearance),
           let appearance = Appearance(rawValue: rawValue) {
            self.appearance = appearance
        } else {
            self.appearance = .translucent
        }
    }

    var usesTranslucentBackground: Bool {
        appearance == .translucent
    }

    var usesBlackBackground: Bool {
        appearance == .black
    }

    func reset() {
        appearance = .translucent
    }
}