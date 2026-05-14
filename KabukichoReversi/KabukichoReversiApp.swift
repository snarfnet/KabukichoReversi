import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI
import UIKit

final class AdMobConsentManager: ObservableObject {
    static let shared = AdMobConsentManager()

    @Published private(set) var isReady = false
    private var didStartAds = false
    private var didRequestTracking = false

    func startAdsIfNeeded() {
        guard !didStartAds else { return }
        didStartAds = true
        MobileAds.shared.start(completionHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.isReady = true
            }
        })
    }

    func requestTrackingAuthorizationIfNeeded() {
        guard !didRequestTracking else { return }
        didRequestTracking = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { _ in }
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
                    adMobConsent.startAdsIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    adMobConsent.requestTrackingAuthorizationIfNeeded()
                }
        }
    }
}
