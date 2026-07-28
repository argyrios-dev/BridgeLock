import AppKit
import Foundation

@MainActor
final class UninstallManager: ObservableObject {

    @Published
    private(set) var isUninstalling = false

    func uninstall(
        controller: DesktopLockController,
        loginItemManager: LoginItemManager
    ) async throws {
        guard !controller.isLocked else {
            throw UninstallError.spaceIsLocked
        }

        guard !isUninstalling else {
            throw UninstallError.uninstallAlreadyInProgress
        }

        guard let applicationURL = applicationBundleURL() else {
            throw UninstallError.applicationBundleRequired
        }

        isUninstalling = true

        defer {
            isUninstalling = false
        }

        try await loginItemManager.disable()

        do {
            var resultingURL: NSURL?

            try FileManager.default.trashItem(
                at: applicationURL,
                resultingItemURL: &resultingURL
            )
        } catch {
            throw UninstallError.couldNotMoveApplicationToTrash(error)
        }

        controller.authorizeTermination()
        NSApp.terminate(nil)
    }

    private func applicationBundleURL() -> URL? {
        let bundleURL = Bundle.main.bundleURL.standardizedFileURL

        guard bundleURL.pathExtension.lowercased() == "app" else {
            return nil
        }

        guard FileManager.default.fileExists(atPath: bundleURL.path) else {
            return nil
        }

        return bundleURL
    }
}

enum UninstallError: LocalizedError {

    case spaceIsLocked
    case uninstallAlreadyInProgress
    case applicationBundleRequired
    case couldNotMoveApplicationToTrash(Error)

    var errorDescription: String? {
        switch self {
        case .spaceIsLocked:
            return "Unlock the protected Space before uninstalling BridgeLock."

        case .uninstallAlreadyInProgress:
            return "BridgeLock is already being uninstalled."

        case .applicationBundleRequired:
            return "Uninstallation requires a built BridgeLock.app bundle. The application cannot uninstall itself when running with swift run."

        case .couldNotMoveApplicationToTrash(let error):
            return "BridgeLock could not be moved to the Trash: \(error.localizedDescription)"
        }
    }
}