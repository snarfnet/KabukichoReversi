import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

@main
struct KabukichoReversiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { phase in
                    if phase == .active && !attRequested {
                        attRequested = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            ATTrackingManager.requestTrackingAuthorization { _ in
                                GADMobileAds.sharedInstance().start(completionHandler: nil)
                            }
                        }
                    }
                }
        }
    }
}
