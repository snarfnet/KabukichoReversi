import SwiftUI

struct ContentView: View {
    @State private var showGame = false
    @State private var selectedPlayer: PlayerID = .p1

    var body: some View {
        ZStack {
            KTheme.bg.ignoresSafeArea()
            NightStreetBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if showGame {
                GameView()
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
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

        ScrollView {
            VStack(spacing: 22) {
                Spacer().frame(height: 30)

                // Title
                VStack(spacing: 8) {
                    Text("KABUKICHO")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(6)
                        .foregroundColor(KTheme.neonCyan)

                    Text("歌舞伎町")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(KTheme.neon)
                        .shadow(color: KTheme.neon.opacity(0.6), radius: 20)

                    Text("リバース")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(KTheme.text)
                }

                Text("4人のメンヘラゴスロリが\n歌舞伎町の路上でリバース対決")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(KTheme.sub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // Character select
                VStack(alignment: .leading, spacing: 12) {
                    Text("あなたのキャラ")
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

                // Start button
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
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(KTheme.neon)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: KTheme.neon.opacity(0.4), radius: 20, y: 8)
                }
                .buttonStyle(.plain)

                // Rules
                rulesCard

                BannerAdView()
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        } // ZStack
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
                Text(pieceName(player))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(ch.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selected ? ch.color.opacity(0.18) : KTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? ch.color.opacity(0.6) : KTheme.line, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func pieceName(_ player: PlayerID) -> String {
        switch player {
        case .p1: return "赤リップ"
        case .p2: return "ストゼロ"
        case .p3: return "ネイルチップ"
        case .p4: return "チョコ空き箱"
        }
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("ルール", systemImage: "book.fill")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(KTheme.neonCyan)

            VStack(alignment: .leading, spacing: 6) {
                ruleRow("1", "10×10のボードで4人対戦")
                ruleRow("2", "自分の駒で相手を挟むとひっくり返せる")
                ruleRow("3", "全員置けなくなったら終了")
                ruleRow("4", "駒が一番多い人の勝ち")
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
        }
    }
}
