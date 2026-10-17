import SwiftUI

@main
struct NFCVaultDemoApp: App {
    @StateObject private var vault = TagVault()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vault)
        }
    }
}

