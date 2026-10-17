import CoreNFC
import Foundation
import Combine

@MainActor
final class NFCReaderService: NSObject, ObservableObject {
    @Published private(set) var isScanning = false
    @Published private(set) var lastError: String?
    @Published private(set) var latestProfile: NFCTagProfile?

    private var session: NFCNDEFReaderSession?

    func beginNDEFScan() {
        guard NFCNDEFReaderSession.readingAvailable else {
            lastError = "這台裝置沒有可用的 NFC 讀取能力。"
            return
        }

        lastError = nil
        latestProfile = nil
        isScanning = true

        let newSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        newSession.alertMessage = "請將 NDEF 標籤貼近 iPhone 上方。"
        session = newSession
        newSession.begin()
    }
}

extension NFCReaderService: NFCNDEFReaderSessionDelegate {
    nonisolated func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        let snapshots = messages.flatMap { message in
            message.records.map { record in
                NFCRecordSnapshot(
                    id: UUID(),
                    typeNameFormat: record.typeNameFormat.displayName,
                    typeHex: record.type.hexString,
                    identifierHex: record.identifier.hexString,
                    payloadHex: record.payload.hexString,
                    decodedText: record.decodedText
                )
            }
        }

        let profile = NFCTagProfile(
            id: UUID(),
            alias: "NDEF 標籤",
            scannedAt: Date(),
            source: "Core NFC / NDEF",
            records: snapshots,
            localSimulationEnabled: false
        )

        Task { @MainActor [weak self] in
            self?.latestProfile = profile
            self?.isScanning = false
            self?.session = nil
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let message: String?
        if let nfcError = error as? NFCReaderError,
           nfcError.code == .readerSessionInvalidationErrorUserCanceled ||
           nfcError.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
            message = nil
        } else {
            message = error.localizedDescription
        }

        Task { @MainActor [weak self] in
            self?.isScanning = false
            self?.session = nil
            self?.lastError = message
        }
    }

}

private extension NFCTypeNameFormat {
    var displayName: String {
        switch self {
        case .empty: return "empty"
        case .nfcWellKnown: return "NFC Well Known"
        case .media: return "MIME media"
        case .absoluteURI: return "Absolute URI"
        case .nfcExternal: return "NFC External"
        case .unchanged: return "Unchanged"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

private extension NFCNDEFPayload {
    var decodedText: String? {
        guard typeNameFormat == .nfcWellKnown, type == Data([0x54]), !payload.isEmpty else {
            return nil
        }

        let languageLength = Int(payload[0] & 0x3F)
        guard payload.count > languageLength + 1 else { return nil }
        return String(data: Data(payload.dropFirst(languageLength + 1)), encoding: .utf8)
    }
}

private extension Data {
    var hexString: String {
        map { String(format: "%02X", $0) }.joined()
    }
}

