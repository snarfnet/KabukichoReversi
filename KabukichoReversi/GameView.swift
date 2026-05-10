import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        VStack(spacing: 0) {
        BannerAdView(adUnitID: "ca-app-pub-9404799280370656/8888721919")
            .frame(height: 50)
            .background(Color.black)

        ZStack {
            KTheme.bg.ignoresSafeArea()
            NightStreetBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            GeometryReader { geo in
                let maxBoard = min(geo.size.width - 24, geo.size.height * 0.52, 500.0)
                ScrollView {
                    VStack(spacing: 14) {
                        scoreBar

                        if let (player, line, event) = vm.dialogue {
                            DialogueBubble(player: player, text: line, event: event)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        BoardView(vm: vm, boardSize: maxBoard)
                            .frame(width: maxBoard, height: maxBoard)

                        turnIndicator

                        if vm.isThinking {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(KTheme.neon)
                                Text("\(Characters.character(for: vm.board.current).name)が考え中...")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(KTheme.sub)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
            }

            if vm.showResult {
                ResultOverlay(vm: vm)
                    .transition(.opacity)
            }
        }
        BannerAdView(adUnitID: "ca-app-pub-9404799280370656/3109781626")
            .frame(height: 50)
            .background(Color.black)
        } // VStack
        .onAppear {
            if !vm.gameStarted {
                vm.startGame(as: .p1)
            }
        }
    }

    @State private var glowPhase: CGFloat = 0

    private var scoreBar: some View {
        HStack(spacing: 6) {
            ForEach(PlayerID.allCases, id: \.rawValue) { player in
                let ch = Characters.character(for: player)
                let count = vm.board.count(for: player)
                let isCurrent = vm.board.current == player && !vm.board.isGameOver

                VStack(spacing: 4) {
                    Image(ch.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(
                                    isCurrent ? ch.color : .clear,
                                    lineWidth: isCurrent ? 2.5 : 0
                                )
                        )
                        .shadow(color: isCurrent ? ch.color.opacity(0.5 + 0.3 * sin(glowPhase)) : .clear, radius: isCurrent ? 8 : 0)

                    Text(ch.name)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(isCurrent ? KTheme.text : KTheme.sub)
                    Text("\(count)")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(ch.color)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(isCurrent ? ch.color.opacity(0.15) : KTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isCurrent ? ch.color.opacity(0.6) : KTheme.line, lineWidth: isCurrent ? 2 : 0.5)
                )
                .scaleEffect(isCurrent ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: vm.board.current)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPhase = .pi
            }
        }
    }

    private var turnIndicator: some View {
        let ch = Characters.character(for: vm.board.current)
        return HStack(spacing: 8) {
            if vm.board.current == vm.humanPlayer {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(KTheme.neonCyan)
                Text("あなたのターン")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(KTheme.neonCyan)
            } else {
                Circle()
                    .fill(ch.color)
                    .frame(width: 12, height: 12)
                Text("\(ch.name)のターン")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(ch.color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(KTheme.panel)
        .clipShape(Capsule())
    }
}

struct DialogueBubble: View {
    let player: PlayerID
    let text: String
    var event: Characters.LineEvent = .place

    private func expressionImage(_ ch: GameCharacter) -> String {
        switch event {
        case .flip, .win: return ch.imageHappy
        case .pass, .lose: return ch.imageCry
        case .place: return ch.imageName
        }
    }

    var body: some View {
        let ch = Characters.character(for: player)
        HStack(spacing: 10) {
            Image(expressionImage(ch))
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(Circle().stroke(ch.color, lineWidth: 2))
                .shadow(color: ch.color.opacity(0.5), radius: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(ch.name)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(ch.color)
                Text(text)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(KTheme.text)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(KTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ch.color.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

struct ResultOverlay: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 18) {
                Text("GAME OVER")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundColor(KTheme.neon)

                let rankings = vm.board.rankings()
                let winner = rankings[0]
                let winnerCh = Characters.character(for: winner)

                VStack(spacing: 6) {
                    Text(winnerCh.name)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(winnerCh.color)
                    Text(winner == vm.humanPlayer ? "あなたの勝ち！" : "の勝ち！")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(KTheme.text)
                }

                Text(Characters.randomLine(winner, event: .win))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(KTheme.sub)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(Array(rankings.enumerated()), id: \.element.rawValue) { index, player in
                        let ch = Characters.character(for: player)
                        HStack {
                            Text("\(index + 1).")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(KTheme.sub)
                                .frame(width: 24)
                            Circle()
                                .fill(ch.color)
                                .frame(width: 14, height: 14)
                            Text(ch.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(KTheme.text)
                            Spacer()
                            Text("\(vm.board.count(for: player))枚")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .foregroundColor(ch.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(index == 0 ? ch.color.opacity(0.12) : KTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 8)

                Button {
                    withAnimation { vm.startGame(as: vm.humanPlayer) }
                } label: {
                    Text("もう一回")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(KTheme.neon)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(KTheme.street)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(KTheme.neon.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: KTheme.neon.opacity(0.2), radius: 30)
        }
    }
}

struct NightStreetBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.01, blue: 0.12),
                    Color(red: 0.03, green: 0.01, blue: 0.06),
                ],
                startPoint: .top, endPoint: .bottom
            )
            // Neon glow strips
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [KTheme.neon.opacity(0.08), .clear],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .frame(height: 200)
            }
            // Side neon lines
            HStack {
                Rectangle()
                    .fill(KTheme.neon.opacity(0.04))
                    .frame(width: 2)
                Spacer()
                Rectangle()
                    .fill(KTheme.neonCyan.opacity(0.04))
                    .frame(width: 2)
            }
            .padding(.horizontal, 8)
        }
    }
}
