import Foundation

enum ScreenshotMode {
    case normal
    case title
    case game
    case dialogue
    case result

    static var current: ScreenshotMode {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--screenshot-title") { return .title }
        if args.contains("--screenshot-game") { return .game }
        if args.contains("--screenshot-dialogue") { return .dialogue }
        if args.contains("--screenshot-result") { return .result }
        return .normal
    }

    var startsInGame: Bool {
        switch self {
        case .game, .dialogue, .result:
            return true
        case .normal, .title:
            return false
        }
    }
}
