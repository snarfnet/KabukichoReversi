import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    var adUnitID = "ca-app-pub-3940256099942544/2435281174" // test

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        guard uiView.rootViewController == nil else { return }
        DispatchQueue.main.async {
            if let rootVC = uiView.window?.windowScene?.keyWindow?.rootViewController {
                uiView.rootViewController = rootVC
                uiView.load(Request())
            }
        }
    }
}
