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

    func applyScreenshotMode(_ mode: ScreenshotMode) {
        switch mode {
        case .normal, .title:
            return
        case .game:
            prepareStoreBoard()
        case .dialogue:
            prepareStoreBoard()
            dialogue = (.p1, "ここは赤で決める", .place)
        case .result:
            prepareStoreResult()
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

    private func prepareStoreBoard() {
        var demo = BoardState()
        let pieces: [(Int, Int, PlayerID)] = [
            (2, 5, .p2), (2, 6, .p2),
            (3, 4, .p1), (3, 5, .p1),
            (4, 3, .p3), (4, 4, .p1), (4, 5, .p2),
            (5, 3, .p3), (5, 4, .p3), (5, 5, .p4),
            (6, 5, .p4), (6, 6, .p4)
        ]
        demo.cells = Array(repeating: Array(repeating: nil, count: BoardState.size), count: BoardState.size)
        for (row, col, player) in pieces {
            demo.cells[row][col] = player
        }
        demo.current = humanPlayer
        demo.isGameOver = false
        board = demo
        isThinking = false
        showResult = false
        lastFlipped = ["3,4", "3,5", "4,4"]
    }

    private func prepareStoreResult() {
        var demo = BoardState()
        demo.cells = Array(repeating: Array(repeating: nil, count: BoardState.size), count: BoardState.size)
        let counts: [(PlayerID, Int)] = [(.p1, 34), (.p4, 27), (.p2, 22), (.p3, 17)]
        var index = 0
        for (player, count) in counts {
            for _ in 0..<count {
                demo.cells[index / BoardState.size][index % BoardState.size] = player
                index += 1
            }
        }
        demo.current = humanPlayer
        demo.isGameOver = true
        board = demo
        isThinking = false
        dialogue = nil
        lastFlipped = []
        showResult = true
    }
}
