import SwiftUI

struct BoardView: View {
    @ObservedObject var vm: GameViewModel
    let boardSize: CGFloat

    private var cellSize: CGFloat { boardSize / CGFloat(BoardState.size) }
    private var validMoves: [(Int, Int)] { vm.board.validMoves(for: vm.board.current) }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<BoardState.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<BoardState.size, id: \.self) { col in
                        cellView(row: row, col: col)
                    }
                }
            }
        }
        .background(KTheme.board)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(KTheme.neon.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: KTheme.neon.opacity(0.25), radius: 20)
    }

    private func cellView(row: Int, col: Int) -> some View {
        let isValid = vm.isHumanTurn && validMoves.contains { $0.0 == row && $0.1 == col }
        let key = "\(row),\(col)"
        let isFlashed = vm.lastFlipped.contains(key)

        return ZStack {
            Rectangle()
                .fill(isValid ? KTheme.cellValid : KTheme.cellEmpty)
                .border(KTheme.boardLine, width: 0.5)

            if let player = vm.board.cells[row][col] {
                PieceView(player: player, size: cellSize * 0.78, flashing: isFlashed)
                    .transition(.scale.combined(with: .opacity))
            } else if isValid {
                Circle()
                    .fill(Characters.character(for: vm.board.current).color.opacity(0.25))
                    .frame(width: cellSize * 0.3, height: cellSize * 0.3)
                    .animation(.easeInOut(duration: 0.8).repeatForever(), value: isValid)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.25)) {
                vm.tap(row: row, col: col)
            }
        }
    }
}
