import SwiftUI
import AppTrackingTransparency

@main
struct KabukichoReversiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("didRequestTrackingPermission") private var didRequestTrackingPermission = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestTrackingPermissionIfNeeded()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    requestTrackingPermissionIfNeeded()
                }
        }
    }

    private func requestTrackingPermissionIfNeeded() {
        guard !didRequestTrackingPermission,
              ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        didRequestTrackingPermission = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
