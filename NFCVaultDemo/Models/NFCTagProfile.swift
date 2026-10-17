import Foundation
import Combine

struct NFCRecordSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let typeNameFormat: String
    let typeHex: String
    let identifierHex: String
    let payloadHex: String
    let decodedText: String?
}

struct NFCTagProfile: Codable, Identifiable, Hashable {
    let id: UUID
    var alias: String
    let scannedAt: Date
    let source: String
    let records: [NFCRecordSnapshot]
    var localSimulationEnabled: Bool
}

@MainActor
final class TagVault: ObservableObject {
    @Published var profiles: [NFCTagProfile] = []

    private let storageKey = "nfclab.saved-profiles.v1"

    init() {
        load()
    }

    func add(_ profile: NFCTagProfile) {
        profiles.insert(profile, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        save()
    }

    func update(_ profile: NFCTagProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        save()
    }

    func exportData(for profile: NFCTagProfile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(profile)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        profiles = (try? decoder.decode([NFCTagProfile].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

