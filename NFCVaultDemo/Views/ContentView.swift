import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var reader = NFCReaderService()

    var body: some View {
        TabView {
            ScannerView(reader: reader)
                .tabItem { Label("掃描", systemImage: "wave.3.right") }

            VaultView()
                .tabItem { Label("資料庫", systemImage: "archivebox") }

            LocalSimulationView()
                .tabItem { Label("測試模擬", systemImage: "rectangle.on.rectangle") }
        }
        .tint(.indigo)
    }
}

private struct ScannerView: View {
    @EnvironmentObject private var vault: TagVault
    @ObservedObject var reader: NFCReaderService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.indigo)

                    Text("NDEF 標籤讀取器")
                        .font(.title2.bold())

                    Text("讀取一般 NDEF 訊息並保存為本機測試資料。")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Button {
                        reader.beginNDEFScan()
                    } label: {
                        Label(reader.isScanning ? "等待標籤…" : "掃描 NDEF", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(reader.isScanning)

                    if let error = reader.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let profile = reader.latestProfile {
                        ProfileCard(profile: profile) {
                            vault.add(profile)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("讀取範圍", systemImage: "info.circle")
                            .font(.headline)
                        Text("這個版本保存 NDEF record 的型別與 payload，提供檢視、匯出與 UI 測試。門禁磁扣的私有密鑰、加密區塊與無線仿真由系統與憑證方案管理。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("NFC Vault")
        }
    }
}

private struct ProfileCard: View {
    let profile: NFCTagProfile
    let save: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("已讀取", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Button("儲存") { save() }
                    .buttonStyle(.bordered)
            }

            Text(profile.alias)
                .font(.headline)

            Text("records: \(profile.records.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(profile.records) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.typeNameFormat)
                        .font(.subheadline.bold())
                    Text("payload: \(record.payloadHex)")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    if let text = record.decodedText {
                        Text(text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct VaultView: View {
    @EnvironmentObject private var vault: TagVault

    var body: some View {
        NavigationStack {
            List {
                if vault.profiles.isEmpty {
                    ContentUnavailableView("尚無資料", systemImage: "archivebox", description: Text("掃描 NDEF 後，卡片資料會出現在這裡。"))
                } else {
                    ForEach(vault.profiles) { profile in
                        NavigationLink {
                            ProfileDetailView(profile: profile)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.alias)
                                    .font(.headline)
                                Text("\(profile.source) · \(profile.records.count) records")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: vault.delete)
                }
            }
            .navigationTitle("資料庫")
            .toolbar { EditButton() }
        }
    }
}

private struct ProfileDetailView: View {
    @EnvironmentObject private var vault: TagVault
    @State var profile: NFCTagProfile
    @State private var shareItem: ShareItem?

    var body: some View {
        List {
            Section("基本資料") {
                TextField("別名", text: $profile.alias)
                LabeledContent("來源", value: profile.source)
                LabeledContent("records", value: "\(profile.records.count)")
            }

            Section("NDEF records") {
                ForEach(profile.records) { record in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(record.typeNameFormat).font(.headline)
                        Text("type: \(record.typeHex)").font(.caption.monospaced())
                        Text("id: \(record.identifierHex)").font(.caption.monospaced())
                        Text("payload: \(record.payloadHex)").font(.caption.monospaced())
                        if let text = record.decodedText {
                            Text(text).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .textSelection(.enabled)
                }
            }

            Section {
                Toggle("啟用本地測試模擬", isOn: $profile.localSimulationEnabled)
                Button("匯出 JSON") {
                    guard let data = try? vault.exportData(for: profile) else { return }
                    shareItem = ShareItem(data: data)
                }
            } footer: {
                Text("本地測試模擬只影響這個 App 的流程狀態，不產生 NFC 射頻或門禁憑證。")
            }
        }
        .navigationTitle("卡片詳情")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { vault.update(profile) }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.data])
        }
    }
}

private struct LocalSimulationView: View {
    @State private var token: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 64))
                    .foregroundStyle(.indigo)
                Text("本地測試模擬")
                    .font(.title2.bold())
                Text("用短期 token 驗證 App 內的卡片選取、確認與交易 UI。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("產生測試 token") {
                    token = String(UUID().uuidString.prefix(12))
                }
                .buttonStyle(.borderedProminent)

                if let token {
                    Text(token)
                        .font(.system(.title3, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding()
            .navigationTitle("測試模擬")
        }
    }
}

private struct ShareItem: Identifiable {
    let id = UUID()
    let data: Data
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

