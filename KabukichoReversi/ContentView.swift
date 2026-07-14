import SwiftUI

struct ContentView: View {
    private let screenshotMode = ScreenshotMode.current
    @State private var showGame = ScreenshotMode.current.startsInGame
    @State private var selectedPlayer: PlayerID = .p1

    var body: some View {
        ZStack {
            KTheme.bg.ignoresSafeArea()
            NightStreetBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if showGame {
                GameView(humanPlayer: selectedPlayer)
                    .transition(.opacity)
            } else {
                titleScreen
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var titleScreen: some View {
        ZStack {
            Image("TitleBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            KTheme.bg.opacity(0.45).ignoresSafeArea()
            LinearGradient(
                colors: [.clear, KTheme.bg.opacity(0.7), KTheme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 18) {
                        Spacer(minLength: 16)
                        titleBlock
                        Text("4人のキャラクターが夜の盤面で競う、歌舞伎町風リバーシ")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(KTheme.sub)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        characterPicker
                        startButton
                        rulesCard
                    }
                    .padding(.horizontal, horizontalPadding(for: geo.size.width))
                    .padding(.bottom, 20)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("KABUKICHO")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(5)
                .foregroundColor(KTheme.neonCyan)
                .minimumScaleFactor(0.8)
            Text("歌舞伎町")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(KTheme.neon)
                .shadow(color: KTheme.neon.opacity(0.6), radius: 20)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text("リバーシ")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(KTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }

    private var characterPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("キャラを選ぶ")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(KTheme.sub)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PlayerID.allCases, id: \.rawValue) { player in
                    characterCard(player)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(KTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(KTheme.line, lineWidth: 1)
                )
        )
    }

    private var startButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                showGame = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .black))
                Text("対戦開始")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(KTheme.neon)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: KTheme.neon.opacity(0.4), radius: 20, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func characterCard(_ player: PlayerID) -> some View {
        let ch = Characters.character(for: player)
        let selected = selectedPlayer == player
        return Button {
            selectedPlayer = player
        } label: {
            VStack(spacing: 6) {
                Image(ch.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selected ? ch.color : .clear, lineWidth: 2)
                    )
                    .shadow(color: selected ? ch.color.opacity(0.5) : .clear, radius: 6)
                Text(ch.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(KTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(ch.piece)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(ch.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 122)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(selected ? ch.color.opacity(0.18) : KTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? ch.color.opacity(0.6) : KTheme.line, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("ルール", systemImage: "book.fill")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(KTheme.neonCyan)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 7) {
                ruleRow("1", "10 x 10 の盤面で4人対戦")
                ruleRow("2", "自分の駒で相手の駒をはさんで返す")
                ruleRow("3", "置ける場所がない時は自動でパス")
                ruleRow("4", "最後に駒が一番多いキャラの勝ち")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(KTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(KTheme.line, lineWidth: 1)
                )
        )
    }

    private func ruleRow(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(KTheme.neon)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(KTheme.sub)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < 390 ? 14 : 18
    }
}
