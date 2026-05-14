import SwiftUI

struct GameCharacter {
    let name: String
    let piece: String
    let imageName: String
    let imageHappy: String
    let imageAngry: String
    let imageCry: String
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
            name: "ルナ",
            piece: "リップ",
            imageName: "CharRuna",
            imageHappy: "CharRunaHappy",
            imageAngry: "CharRunaAngry",
            imageCry: "CharRunaCry",
            color: Color(red: 0.85, green: 0.12, blue: 0.25),
            highlight: Color(red: 1.0, green: 0.3, blue: 0.4),
            lines: .init(
                onPlace: ["ここは赤で決める", "そこ、見えてたよ", "この色に染めるね", "一手ずつ詰めるよ"],
                onFlip: ["赤にチェンジ", "まとめて返すよ", "流れは私のもの", "そこ、もらうね"],
                onPass: ["今は置けないみたい", "少し待つしかないね", "次で返すから", "ここは様子見"],
                onWin: ["赤い夜の勝ち", "最後まで見てくれてありがとう", "この街では私が強いよ", "いい勝負だったね"],
                onLose: ["悔しい、もう一回", "次は負けない", "今日は読みが足りなかった", "まだ終わってないから"]
            )
        ),
        .p2: GameCharacter(
            name: "アイリ",
            piece: "ボトル",
            imageName: "CharAiri",
            imageHappy: "CharAiriHappy",
            imageAngry: "CharAiriAngry",
            imageCry: "CharAiriCry",
            color: Color(red: 0.20, green: 0.75, blue: 0.35),
            highlight: Color(red: 0.30, green: 0.90, blue: 0.45),
            lines: .init(
                onPlace: ["ここは緑で置くよ", "まだまだ飲める", "この一手は強いよ", "流れを作るね"],
                onFlip: ["一気に返すよ", "緑に染まったね", "いい感じに決まった", "流れを持っていくね"],
                onPass: ["ちょっと休憩", "今は置ける場所がないね", "次で巻き返す", "まだ酔ってないよ"],
                onWin: ["勝利の一杯だね", "勢いだけじゃないでしょ", "緑の夜、完成", "いい勝負だったよ"],
                onLose: ["もう一本いけるよ", "次は冷静にいく", "今のは油断した", "悔しいけど楽しかった"]
            )
        ),
        .p3: GameCharacter(
            name: "ミユ",
            piece: "ネイル",
            imageName: "CharMiyu",
            imageHappy: "CharMiyuHappy",
            imageAngry: "CharMiyuAngry",
            imageCry: "CharMiyuCry",
            color: Color(red: 0.70, green: 0.30, blue: 0.85),
            highlight: Color(red: 0.82, green: 0.45, blue: 0.95),
            lines: .init(
                onPlace: ["ここ、きれいに塗るね", "紫のラインを作る", "爪先まで計算済み", "この色、似合うでしょ"],
                onFlip: ["塗り替え完了", "紫にそろえるね", "その駒、磨いておく", "きれいに決まった"],
                onPass: ["乾くまで待って", "今は置けないみたい", "焦らず次を見る", "一度整えるね"],
                onWin: ["一番きれいな盤面だね", "仕上がり、完璧", "紫の勝ち", "ちゃんと勝ったよ"],
                onLose: ["ネイルが乱れたかも", "次はもっと丁寧にいく", "悔しいな", "塗り直して再開したい"]
            )
        ),
        .p4: GameCharacter(
            name: "ユメ",
            piece: "チョコ",
            imageName: "CharYume",
            imageHappy: "CharYumeHappy",
            imageAngry: "CharYumeAngry",
            imageCry: "CharYumeCry",
            color: Color(red: 0.85, green: 0.55, blue: 0.20),
            highlight: Color(red: 0.95, green: 0.70, blue: 0.30),
            lines: .init(
                onPlace: ["ここに甘く置くよ", "チョコの角度、完璧", "じわっと広げるよ", "この一手、甘くないよ"],
                onFlip: ["全部チョコ色にする", "甘いけど強いでしょ", "そこ、いただきます", "きれいに返せた"],
                onPass: ["チョコ休憩するね", "置ける場所がないみたい", "次は甘くないよ", "少し待ってね"],
                onWin: ["甘い勝利だね", "チョコの力、見た？", "最後までおいしかった", "また遊ぼうね"],
                onLose: ["苦い結果だね", "次はもっと甘くいく", "まだ食べたりない", "もう一回お願い"]
            )
        ),
    ]

    static func character(for player: PlayerID) -> GameCharacter {
        all[player] ?? all[.p1]!
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
