import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI
import UIKit

final class AdMobConsentManager: ObservableObject {
    static let shared = AdMobConsentManager()

    @Published private(set) var isReady = false
    private var didStart = false

    func requestTrackingAndStartAds() {
        guard !didStart else { return }
        didStart = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    DispatchQueue.main.async {
                        MobileAds.shared.start()
                        self.isReady = true
                    }
                }
            } else {
                MobileAds.shared.start()
                self.isReady = true
            }
        }
    }
}

@main
struct KabukichoReversiApp: App {
    @StateObject private var adMobConsent = AdMobConsentManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    adMobConsent.requestTrackingAndStartAds()
                }
        }
    }
}
