import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: View {
    var adUnitID = "ca-app-pub-9404799280370656/8888721919"
    @ObservedObject private var adMobConsent = AdMobConsentManager.shared

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)

            if adMobConsent.isReady {
                BannerViewContainer(adUnitID: adUnitID, adSize: adSize)
                    .frame(width: adSize.size.width, height: adSize.size.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                adPlaceholder
            }
        }
        .frame(height: 50)
        .accessibilityLabel("広告")
    }

    private var adPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.78))
            Text("広告")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.45))
        }
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.adRootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        banner.adUnitID = adUnitID
        banner.adSize = adSize
        if banner.rootViewController == nil {
            banner.rootViewController = UIApplication.shared.adRootViewController
        }
    }
}

private extension UIApplication {
    var adRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
