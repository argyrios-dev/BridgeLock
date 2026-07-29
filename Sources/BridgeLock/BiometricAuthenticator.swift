import LocalAuthentication
import Foundation

@MainActor
final class BiometricAuthenticator {

    enum BiometricError: LocalizedError, Equatable {
        case notAvailable
        case notEnrolled
        case failed
        case cancelled
        case lockedOut
        case unknown(String)          // ← cambiamos a String para poder ser Equatable

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Touch ID is not available on this Mac."
            case .notEnrolled:
                return "No fingerprints are enrolled in Touch ID."
            case .failed:
                return "Touch ID authentication failed."
            case .cancelled:
                return nil
            case .lockedOut:
                return "Touch ID is locked. Enter your PIN instead."
            case .unknown(let message):
                return message
            }
        }
    }

    static var canEvaluate: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }

    static var biometryTypeName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: nil
        )

        switch context.biometryType {
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometrics"
        @unknown default:
            return "Biometrics"
        }
    }

    static func authenticate(
        reason: String = "Unlock the protected Space"
    ) async -> Result<Void, BiometricError> {

        let context = LAContext()
        context.localizedFallbackTitle = "Use PIN"
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotAvailable:
                    return .failure(.notAvailable)
                case .biometryNotEnrolled:
                    return .failure(.notEnrolled)
                case .biometryLockout:
                    return .failure(.lockedOut)
                default:
                    return .failure(.unknown(laError.localizedDescription))
                }
            }
            return .failure(.notAvailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success ? .success(()) : .failure(.failed)
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .failure(.cancelled)
            case .userFallback:
                return .failure(.cancelled)
            case .biometryLockout:
                return .failure(.lockedOut)
            case .authenticationFailed:
                return .failure(.failed)
            default:
                return .failure(.unknown(laError.localizedDescription))
            }
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
}