import SwiftUI

struct GameCharacter {
    let name: String
    let piece: String
    let color: Color
    let highlight: Color
    let lines: Lines

    struct Lines {
        let onPlace: [String]
        let onFlip: [String]
        let onPass: [String]
        let onWin: [String]
        let onLose: [String]
    }
}

enum Characters {
    static let all: [PlayerID: GameCharacter] = [
        .p1: GameCharacter(
            name: "るな",
            piece: "lipstick",
            color: Color(red: 0.85, green: 0.12, blue: 0.25),
            highlight: Color(red: 1.0, green: 0.3, blue: 0.4),
            lines: .init(
                onPlace: ["あたしの色に染まりなよ", "赤く塗りつぶしてあげる", "逃げないでよ..."],
                onFlip: ["ほら、もうあたしのもの", "全部赤くしちゃう", "きれいでしょ？"],
                onPass: ["...もういいよ", "はぁ...つまんない", "置けないとか最悪"],
                onWin: ["当然でしょ？あたしが一番", "全部あたしの色...最高"],
                onLose: ["は？ありえないんだけど", "...もう知らない"]
            )
        ),
        .p2: GameCharacter(
            name: "あいり",
            piece: "strongzero",
            color: Color(red: 0.20, green: 0.75, blue: 0.35),
            highlight: Color(red: 0.30, green: 0.90, blue: 0.45),
            lines: .init(
                onPlace: ["酔ってるけど手は正確だから", "ストゼロパワーなめんな", "ぷはー、ここね"],
                onFlip: ["飲み込まれろ〜", "酔拳リバーシ舐めんな", "あはは、いただき"],
                onPass: ["うぅ...ちょっと酔った", "パスとかだる...", "もう一缶開けよ"],
                onWin: ["酔っても勝てるし！かんぱーい", "ストゼロは正義"],
                onLose: ["酔ってたからノーカンね", "...おかわり持ってきて"]
            )
        ),
        .p3: GameCharacter(
            name: "みゆ",
            piece: "nail",
            color: Color(red: 0.70, green: 0.30, blue: 0.85),
            highlight: Color(red: 0.82, green: 0.45, blue: 0.95),
            lines: .init(
                onPlace: ["ネイル割れたら許さないから", "この指で奪ってあげる", "きゃは、ここに置くね"],
                onFlip: ["全部あたしのデザインに変えちゃお", "はい、塗り替え完了", "かわいくしてあげた"],
                onPass: ["爪乾かしてるから待って", "えー、置けないの？最悪", "...退屈"],
                onWin: ["ネイルアートの勝利！", "あたしのセンスが証明されたね"],
                onLose: ["ネイル割れたし最悪...", "もうやだ帰る"]
            )
        ),
        .p4: GameCharacter(
            name: "ゆめ",
            piece: "chocolate",
            color: Color(red: 0.85, green: 0.55, blue: 0.20),
            highlight: Color(red: 0.95, green: 0.70, blue: 0.30),
            lines: .init(
                onPlace: ["甘いの食べたい...ここね", "チョコあげるから許して", "...えへへ"],
                onFlip: ["全部チョコにしちゃうね", "甘くて溶けちゃうでしょ", "もぐもぐ...いただき"],
                onPass: ["チョコ食べてるから待って...", "...お腹いっぱい", "もうないの...チョコ..."],
                onWin: ["チョコは裏切らないね...", "甘い勝利...えへへ"],
                onLose: ["チョコ全部食べられちゃった...", "...泣きそう"]
            )
        ),
    ]

    static func character(for player: PlayerID) -> GameCharacter {
        all[player]!
    }

    static func randomLine(_ player: PlayerID, event: LineEvent) -> String {
        let ch = character(for: player)
        let lines: [String]
        switch event {
        case .place: lines = ch.lines.onPlace
        case .flip: lines = ch.lines.onFlip
        case .pass: lines = ch.lines.onPass
        case .win: lines = ch.lines.onWin
        case .lose: lines = ch.lines.onLose
        }
        return lines.randomElement() ?? ""
    }

    enum LineEvent {
        case place, flip, pass, win, lose
    }
}
