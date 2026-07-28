import CryptoKit
import Foundation
@preconcurrency import Security

final class PINStore: ObservableObject {

    @Published
    private(set) var hasPIN: Bool

    private static let currentService = "com.bridgelock.security-pin.v2"
    private static let currentAccount = "primary-pin"

    private static let legacyServices = [
        "com.bridgelock.security-pin",
        "BridgeLock",
        "BridgeLock.PIN"
    ]

    private static let saltLength = 32
    private static let digestLength = 32
    private static let minimumPINLength = 4
    private static let maximumPINLength = 12

    init() {
        Self.removeLegacyPINs()

        hasPIN = Self.readStoredPINData() != nil
    }

    static var hasStoredPIN: Bool {
        readStoredPINData() != nil
    }

    func saveNewPIN(_ pin: String) throws {
        try validate(pin: pin)

        let salt = try Self.generateRandomData(
            count: Self.saltLength
        )

        let digest = Self.makeDigest(
            pin: pin,
            salt: salt
        )

        var storedData = Data()
        storedData.append(salt)
        storedData.append(digest)

        try Self.saveToKeychain(storedData)

        hasPIN = true
    }

    func verify(pin: String) -> Bool {
        guard Self.isValidPINFormat(pin) else {
            return false
        }

        guard let storedData = Self.readStoredPINData() else {
            hasPIN = false
            return false
        }

        let requiredLength =
            Self.saltLength +
            Self.digestLength

        guard storedData.count == requiredLength else {
            Self.deleteCurrentKeychainItem()
            hasPIN = false
            return false
        }

        let saltRange = 0..<Self.saltLength
        let digestRange =
            Self.saltLength..<requiredLength

        let salt = storedData.subdata(
            in: saltRange
        )

        let storedDigest = storedData.subdata(
            in: digestRange
        )

        let enteredDigest = Self.makeDigest(
            pin: pin,
            salt: salt
        )

        return Self.constantTimeComparison(
            storedDigest,
            enteredDigest
        )
    }

    func deletePIN() throws {
        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,
            kSecAttrService as String:
                Self.currentService,
            kSecAttrAccount as String:
                Self.currentAccount
        ]

        let status = SecItemDelete(
            query as CFDictionary
        )

        guard status == errSecSuccess ||
              status == errSecItemNotFound else {
            throw PINStoreError.keychainFailure(
                status
            )
        }

        hasPIN = false
    }

    func resetPIN() throws {
        try deletePIN()
    }

    func refreshState() {
        hasPIN = Self.readStoredPINData() != nil
    }

    private func validate(pin: String) throws {
        guard Self.isValidPINFormat(pin) else {
            throw PINStoreError.invalidPINFormat
        }
    }

    private static func isValidPINFormat(
        _ pin: String
    ) -> Bool {
        guard (
            minimumPINLength...maximumPINLength
        ).contains(pin.count) else {
            return false
        }

        return pin.allSatisfy {
            $0.isASCII && $0.isNumber
        }
    }

    private static func makeDigest(
        pin: String,
        salt: Data
    ) -> Data {
        var input = Data()
        input.append(salt)
        input.append(contentsOf: pin.utf8)

        let firstDigest = SHA256.hash(
            data: input
        )

        var workingData = Data(firstDigest)

        for _ in 0..<100_000 {
            var iterationInput = Data()
            iterationInput.append(salt)
            iterationInput.append(workingData)

            workingData = Data(
                SHA256.hash(
                    data: iterationInput
                )
            )
        }

        return workingData
    }

    private static func generateRandomData(
        count: Int
    ) throws -> Data {
        var bytes = [UInt8](
            repeating: 0,
            count: count
        )

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            bytes.count,
            &bytes
        )

        guard status == errSecSuccess else {
            throw PINStoreError.randomGenerationFailure(
                status
            )
        }

        return Data(bytes)
    }

    private static func saveToKeychain(
        _ data: Data
    ) throws {
        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,
            kSecAttrService as String:
                currentService,
            kSecAttrAccount as String:
                currentAccount
        ]

        let attributes: [String: Any] = [
            kSecValueData as String:
                data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw PINStoreError.keychainFailure(
                updateStatus
            )
        }

        var insertionQuery = query

        for (key, value) in attributes {
            insertionQuery[key] = value
        }

        let addStatus = SecItemAdd(
            insertionQuery as CFDictionary,
            nil
        )

        guard addStatus == errSecSuccess else {
            throw PINStoreError.keychainFailure(
                addStatus
            )
        }
    }

    private static func readStoredPINData() -> Data? {
        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,
            kSecAttrService as String:
                currentService,
            kSecAttrAccount as String:
                currentAccount,
            kSecReturnData as String:
                true,
            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    private static func deleteCurrentKeychainItem() {
        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,
            kSecAttrService as String:
                currentService,
            kSecAttrAccount as String:
                currentAccount
        ]

        SecItemDelete(
            query as CFDictionary
        )
    }

    private static func removeLegacyPINs() {
        for service in legacyServices {
            let query: [String: Any] = [
                kSecClass as String:
                    kSecClassGenericPassword,
                kSecAttrService as String:
                    service
            ]

            SecItemDelete(
                query as CFDictionary
            )
        }
    }

    private static func constantTimeComparison(
        _ first: Data,
        _ second: Data
    ) -> Bool {
        guard first.count == second.count else {
            return false
        }

        var difference: UInt8 = 0

        for index in first.indices {
            difference |= first[index] ^ second[index]
        }

        return difference == 0
    }
}

enum PINStoreError: LocalizedError {

    case invalidPINFormat
    case randomGenerationFailure(OSStatus)
    case keychainFailure(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidPINFormat:
            return "PIN must contain between 4 and 12 digits."

        case .randomGenerationFailure(let status):
            return "BridgeLock could not generate secure random data. Security status: \(status)."

        case .keychainFailure(let status):
            return "BridgeLock could not access the macOS Keychain. Security status: \(status)."
        }
    }
}