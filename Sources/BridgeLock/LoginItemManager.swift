import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager: ObservableObject {

    @Published
    private(set) var isEnabled = false

    @Published
    private(set) var statusDescription = "Not registered"

    @Published
    private(set) var errorMessage: String?

    private let service: SMAppService

    init(service: SMAppService = .mainApp) {
        self.service = service
        refreshStatus()
    }

    func refreshStatus() {
        switch service.status {
        case .enabled:
            isEnabled = true
            statusDescription = "Enabled"

        case .requiresApproval:
            isEnabled = false
            statusDescription = "Approval required in System Settings"

        case .notRegistered:
            isEnabled = false
            statusDescription = "Not registered"

        case .notFound:
            isEnabled = false
            statusDescription = "Application bundle not found"

        @unknown default:
            isEnabled = false
            statusDescription = "Unknown status"
        }
    }

    func setEnabled(_ enabled: Bool) async {
        errorMessage = nil

        do {
            if enabled {
                try service.register()
            } else {
                try await unregister()
            }

            refreshStatus()
        } catch {
            refreshStatus()
            errorMessage = error.localizedDescription
        }
    }

    func disable() async throws {
        guard service.status != .notRegistered else {
            refreshStatus()
            return
        }

        try await unregister()
        refreshStatus()
    }

    private func unregister() async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in

            service.unregister { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}