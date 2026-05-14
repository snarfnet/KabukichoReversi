import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
final class AdMobStartup: ObservableObject {
    static let shared = AdMobStartup()

    @Published private(set) var isReady = false
    private var didStart = false

    func startAdsAfterLaunch() async {
        guard !didStart else { return }
        didStart = true
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        try? await Task.sleep(for: .seconds(1))

        MobileAds.shared.start { [weak self] _ in
            Task { @MainActor in
                self?.isReady = true
            }
        }
    }
}

@main
struct KabukichoReversiApp: App {
    @StateObject private var adMobStartup = AdMobStartup.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task {
                        await adMobStartup.startAdsAfterLaunch()
                    }
                }
        }
    }
}
