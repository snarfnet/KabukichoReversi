import Foundation

enum PlayerID: Int, CaseIterable, Codable {
    case p1 = 1, p2, p3, p4

    var next: PlayerID {
        switch self {
        case .p1: return .p2
        case .p2: return .p3
        case .p3: return .p4
        case .p4: return .p1
        }
    }
}

struct BoardState {
    static let size = 10
    var cells: [[PlayerID?]]
    var current: PlayerID = .p1
    var passed: Set<PlayerID> = []
    var isGameOver = false

    init() {
        cells = Array(repeating: Array(repeating: nil, count: Self.size), count: Self.size)
        let mid = Self.size / 2
        cells[mid - 1][mid - 1] = .p1
        cells[mid - 1][mid]     = .p2
        cells[mid][mid - 1]     = .p3
        cells[mid][mid]         = .p4
    }

    func count(for player: PlayerID) -> Int {
        cells.flatMap { $0 }.filter { $0 == player }.count
    }

    func validMoves(for player: PlayerID) -> [(Int, Int)] {
        var moves: [(Int, Int)] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if cells[r][c] == nil && !flips(row: r, col: c, player: player).isEmpty {
                    moves.append((r, c))
                }
            }
        }
        return moves
    }

    func flips(row: Int, col: Int, player: PlayerID) -> [(Int, Int)] {
        guard row >= 0, row < Self.size, col >= 0, col < Self.size else { return [] }
        guard cells[row][col] == nil else { return [] }
        var result: [(Int, Int)] = []
        let directions = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
        for (dr, dc) in directions {
            var path: [(Int, Int)] = []
            var r = row + dr, c = col + dc
            while r >= 0 && r < Self.size && c >= 0 && c < Self.size {
                guard let occupant = cells[r][c] else { break }
                if occupant == player {
                    result.append(contentsOf: path)
                    break
                }
                path.append((r, c))
                r += dr; c += dc
            }
        }
        return result
    }

    mutating func place(row: Int, col: Int) -> Bool {
        let toFlip = flips(row: row, col: col, player: current)
        guard !toFlip.isEmpty else { return false }
        cells[row][col] = current
        for (r, c) in toFlip {
            cells[r][c] = current
        }
        passed = []
        advanceTurn()
        return true
    }

    mutating func advanceTurn() {
        var next = current.next
        for _ in 0..<4 {
            if !validMoves(for: next).isEmpty {
                current = next
                return
            }
            passed.insert(next)
            next = next.next
        }
        isGameOver = true
    }

    func rankings() -> [PlayerID] {
        PlayerID.allCases.sorted { count(for: $0) > count(for: $1) }
    }
}

// Simple AI — picks move that flips the most pieces, with corner/edge preference
struct ReversiAI {
    static func bestMove(board: BoardState) -> (Int, Int)? {
        let moves = board.validMoves(for: board.current)
        guard !moves.isEmpty else { return nil }
        let size = BoardState.size
        let corners: Set<String> = ["0,0", "0,\(size-1)", "\(size-1),0", "\(size-1),\(size-1)"]

        return moves.max(by: { a, b in
            score(a, board: board, corners: corners) < score(b, board: board, corners: corners)
        })
    }

    private static func score(_ move: (Int, Int), board: BoardState, corners: Set<String>) -> Int {
        let flipCount = board.flips(row: move.0, col: move.1, player: board.current).count
        let key = "\(move.0),\(move.1)"
        let cornerBonus = corners.contains(key) ? 100 : 0
        let edgeBonus = (move.0 == 0 || move.0 == BoardState.size - 1 || move.1 == 0 || move.1 == BoardState.size - 1) ? 10 : 0
        return flipCount + cornerBonus + edgeBonus
    }
}
