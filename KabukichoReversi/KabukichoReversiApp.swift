import GoogleMobileAds
import SwiftUI

@MainActor
final class AdMobStartup: ObservableObject {
    static let shared = AdMobStartup()

    @Published private(set) var isReady = false
    private var didStart = false

    func startAdsAfterLaunch() async {
        guard !didStart else { return }
        didStart = true

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
