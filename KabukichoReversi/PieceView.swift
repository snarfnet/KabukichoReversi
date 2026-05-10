import SwiftUI

struct PieceView: View {
    let player: PlayerID
    let size: CGFloat
    var flashing = false

    private var ch: GameCharacter { Characters.character(for: player) }

    private var pieceImageName: String {
        switch player {
        case .p1: return "PieceLipstick"
        case .p2: return "PieceStrongZero"
        case .p3: return "PieceNail"
        case .p4: return "PieceChocolate"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(ch.color.opacity(0.7))
                .shadow(color: ch.highlight.opacity(0.6), radius: flashing ? 8 : 3)

            Image(pieceImageName)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.75, height: size * 0.75)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .scaleEffect(flashing ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: flashing)
    }
}
