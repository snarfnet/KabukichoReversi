import SwiftUI

struct PieceView: View {
    let player: PlayerID
    let size: CGFloat
    var flashing = false

    private var ch: GameCharacter { Characters.character(for: player) }

    var body: some View {
        ZStack {
            Circle()
                .fill(ch.color.opacity(0.85))
                .shadow(color: ch.highlight.opacity(0.6), radius: flashing ? 8 : 3)

            pieceIcon
                .font(.system(size: size * 0.42))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .scaleEffect(flashing ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: flashing)
    }

    @ViewBuilder
    private var pieceIcon: some View {
        switch player {
        case .p1:
            // Lipstick
            Image(systemName: "mouth.fill")
        case .p2:
            // Strong Zero
            Image(systemName: "cup.and.saucer.fill")
        case .p3:
            // Nail
            Image(systemName: "hand.raised.fingers.spread.fill")
        case .p4:
            // Chocolate
            Image(systemName: "gift.fill")
        }
    }
}
