import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    @Published var board = BoardState()
    @Published var dialogue: (PlayerID, String, Characters.LineEvent)? = nil
    @Published var lastFlipped: Set<String> = []
    @Published var isThinking = false
    @Published var humanPlayer: PlayerID = .p1
    @Published var gameStarted = false
    @Published var showResult = false

    var isHumanTurn: Bool {
        board.current == humanPlayer && !board.isGameOver
    }

    func startGame(as player: PlayerID) {
        board = BoardState()
        humanPlayer = player
        gameStarted = true
        showResult = false
        dialogue = nil
        lastFlipped = []

        if !isHumanTurn {
            scheduleAI()
        }
    }

    func tap(row: Int, col: Int) {
        guard isHumanTurn else { return }
        let moves = board.validMoves(for: board.current)
        guard moves.contains(where: { $0.0 == row && $0.1 == col }) else { return }

        let flipped = board.flips(row: row, col: col, player: board.current)
        let player = board.current
        _ = board.place(row: row, col: col)

        lastFlipped = Set(flipped.map { "\($0.0),\($0.1)" })
        showLine(player, event: flipped.count >= 2 ? .flip : .place)

        checkEndOrContinue()
    }

    private func scheduleAI() {
        guard !board.isGameOver else {
            showResult = true
            return
        }
        guard board.current != humanPlayer else { return }

        isThinking = true
        let delay = Double.random(in: 0.6...1.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.executeAI()
        }
    }

    private func executeAI() {
        isThinking = false
        guard !board.isGameOver else {
            showResult = true
            return
        }

        let player = board.current
        if let move = ReversiAI.bestMove(board: board) {
            let flipped = board.flips(row: move.0, col: move.1, player: board.current)
            _ = board.place(row: move.0, col: move.1)
            lastFlipped = Set(flipped.map { "\($0.0),\($0.1)" })
            showLine(player, event: flipped.count >= 2 ? .flip : .place)
        } else {
            showLine(player, event: .pass)
            board.passed.insert(player)
            board.advanceTurn()
        }

        checkEndOrContinue()
    }

    private func checkEndOrContinue() {
        if board.isGameOver {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.showResult = true
            }
        } else if board.current != humanPlayer {
            scheduleAI()
        } else {
            let moves = board.validMoves(for: humanPlayer)
            if moves.isEmpty {
                showLine(humanPlayer, event: .pass)
                board.passed.insert(humanPlayer)
                board.advanceTurn()
                checkEndOrContinue()
            }
        }
    }

    private func showLine(_ player: PlayerID, event: Characters.LineEvent) {
        let line = Characters.randomLine(player, event: event)
        withAnimation(.spring(response: 0.3)) {
            dialogue = (player, line, event)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            if self?.dialogue?.1 == line {
                withAnimation { self?.dialogue = nil }
            }
        }
    }
}
