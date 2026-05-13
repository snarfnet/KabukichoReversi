import SwiftUI

struct BannerAdView: View {
    var adUnitID = ""

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.78))
            Text("広告")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .accessibilityLabel("広告")
    }
}
