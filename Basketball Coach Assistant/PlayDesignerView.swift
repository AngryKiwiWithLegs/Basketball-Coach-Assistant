import SwiftUI

struct PlayDesignerRootViews: View {
    @StateObject private var doc = PlayDocument()
    @State private var selectedTool: ToolMode = .select
    @State private var selectedArrowType: PlayArrow.ArrowType = .straight
    @State private var selectedPlayerID: UUID? = nil
    @State private var activeArrowPoints: [CGPoint] = []

    // Animation state
    @State private var isPlaying = false
    @State private var playerProgressMap: [UUID: CGFloat] = [:]
    @State private var animationTimer: Timer? = nil
    @State private var originalPositions: [UUID: CGPoint] = [:]
    @State private var playerArrowMap: [UUID: [CGPoint]] = [:]

    // Selected player for speed editing
    private var selectedPlayer: Binding<PlayerToken>? {
        guard let id = selectedPlayerID,
              let index = doc.players.firstIndex(where: { $0.id == id })
        else { return nil }
        return Binding(
            get: { self.doc.players[index] },
            set: { self.doc.players[index] = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            PlayDesignerToolbar(
                selectedTool:      $selectedTool,
                selectedArrowType: $selectedArrowType,
                isPlaying:         $isPlaying,
                canUndo:           !doc.arrows.isEmpty || !doc.players.isEmpty,
                onUndo: {
                    if !doc.arrows.isEmpty { doc.removeLastArrow() }
                    else if !doc.players.isEmpty { doc.players.removeLast() }
                },
                onClear: {
                    stopAnimation()
                    doc.clear()
                    activeArrowPoints = []
                    selectedPlayerID = nil
                },
                onPlayStop: {
                    if isPlaying { stopAnimation() } else { startAnimation() }
                }
            )
            .zIndex(1)

            GeometryReader { courtGeo in
                ZStack {
                    HalfCourtShape()

                    ArrowsOverlay(arrows: doc.arrows, activePoints: activeArrowPoints)

                    ForEach(doc.players) { player in
                        PlayerTokenView(
                            token: player,
                            isSelected: selectedPlayerID == player.id,
                            tokenSize: courtGeo.size.width * 0.06,
                            onDrag: { newPos in
                                guard !isPlaying else { return }
                                movePlayer(id: player.id,
                                           to: clamped(newPos, in: courtGeo.size))
                            },
                            onTap: {
                                guard !isPlaying else { return }
                                if selectedTool == .erase {
                                    doc.removePlayer(id: player.id)
                                    selectedPlayerID = nil
                                } else {
                                    selectedPlayerID =
                                        selectedPlayerID == player.id ? nil : player.id
                                }
                            },
                            onDelete: {
                                guard !isPlaying else { return }
                                doc.removePlayer(id: player.id)
                                selectedPlayerID = nil
                            }
                        )
                    }

                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 4)
                                .onChanged { value in
                                    guard selectedTool == .drawArrow, !isPlaying else { return }
                                    let pt = clamped(value.location, in: courtGeo.size)
                                    if activeArrowPoints.isEmpty {
                                        activeArrowPoints = [pt]
                                    } else if let last = activeArrowPoints.last,
                                              dist(last, pt) > 8 {
                                        activeArrowPoints.append(pt)
                                    }
                                }
                                .onEnded { _ in
                                    guard !isPlaying else { return }
                                    if selectedTool == .drawArrow,
                                       activeArrowPoints.count >= 2 {
                                        doc.addArrow(PlayArrow(
                                            points: activeArrowPoints,
                                            arrowType: selectedArrowType))
                                    }
                                    activeArrowPoints = []
                                }
                        )
                        .onTapGesture { location in
                            guard !isPlaying else { return }
                            let pt = clamped(location, in: courtGeo.size)
                            switch selectedTool {
                            case .addOffense: doc.addPlayer(at: pt, team: .offense)
                            case .addDefense: doc.addPlayer(at: pt, team: .defense)
                            case .select:     selectedPlayerID = nil
                            default: break
                            }
                        }
                }
                .cornerRadius(8)
            }
            .padding(12)
            .clipped()
            .background(Color(white: 0.10))
            .zIndex(0)

            // Speed panel — shows when a player is selected in select mode
            if !isPlaying,
               selectedTool == .select,
               let id = selectedPlayerID,
               let index = doc.players.firstIndex(where: { $0.id == id }) {
                speedPanel(index: index)
                    .zIndex(1)
            }

            HStack {
                Label("\(doc.players.filter{$0.team == .offense}.count) Offense",
                      systemImage: "person.circle.fill").foregroundColor(.blue)
                Spacer()
                if isPlaying {
                    Text("Simulating...")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                } else {
                    Label("\(doc.arrows.count) Arrows",
                          systemImage: "arrow.up.right").foregroundColor(.yellow)
                }
                Spacer()
                Label("\(doc.players.filter{$0.team == .defense}.count) Defense",
                      systemImage: "xmark.circle.fill").foregroundColor(.red)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color(white: 0.12))
            .zIndex(1)
        }
        .background(Color(white: 0.08).ignoresSafeArea())
    }

    // MARK: - Speed Panel

    private func speedPanel(index: Int) -> some View {
        let player = doc.players[index]
        let teamLabel = player.team == .offense ? "Offense \(player.number)" : "Defense \(player.number)"
        let speedColor: Color = {
            if player.speed < 0.9 { return .blue }
            if player.speed > 1.5 { return .red }
            return .green
        }()
        let speedDescription: String = {
            if player.speed < 0.75 { return "Slow" }
            if player.speed < 1.0  { return "Below Average" }
            if player.speed < 1.3  { return "Normal" }
            if player.speed < 1.7  { return "Fast" }
            return "Sprint"
        }()

        return HStack(spacing: 16) {
            Image(systemName: "figure.run")
                .foregroundColor(speedColor)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(teamLabel) — Speed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                Text(speedDescription)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(speedColor)
            }

            Slider(value: $doc.players[index].speed, in: 0.5...2.5, step: 0.1)
                .tint(speedColor)

            Text(String(format: "%.1fx", player.speed))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(speedColor)
                .frame(width: 40)

            // Quick preset buttons
            HStack(spacing: 6) {
                SpeedPresetBtn(label: "0.5x", value: 0.5,
                               current: player.speed) { doc.players[index].speed = 0.5 }
                SpeedPresetBtn(label: "1x",   value: 1.0,
                               current: player.speed) { doc.players[index].speed = 1.0 }
                SpeedPresetBtn(label: "2x",   value: 2.0,
                               current: player.speed) { doc.players[index].speed = 2.0 }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(white: 0.15))
    }

    // MARK: - Animation

    private func startAnimation() {
        guard !doc.players.isEmpty, !doc.arrows.isEmpty else { return }

        originalPositions = Dictionary(
            uniqueKeysWithValues: doc.players.map { ($0.id, $0.position) }
        )

        playerArrowMap = [:]
        for arrow in doc.arrows {
            guard let startPt = arrow.points.first else { continue }
            if let player = doc.players.min(by: {
                dist($0.position, startPt) < dist($1.position, startPt)
            }), dist(player.position, startPt) < 80 {
                playerArrowMap[player.id] = arrow.points
            }
        }

        guard !playerArrowMap.isEmpty else { return }

        // Initialise each player's progress to 0
        playerProgressMap = Dictionary(
            uniqueKeysWithValues: playerArrowMap.keys.map { ($0, CGFloat(0)) }
        )

        isPlaying = true
        selectedPlayerID = nil

        let baseIncrement: CGFloat = 0.010

        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0,
                                              repeats: true) { _ in
            var allDone = true

            for id in playerArrowMap.keys {
                guard let playerIndex = doc.players.firstIndex(where: { $0.id == id }),
                      var progress = playerProgressMap[id],
                      let pathPoints = playerArrowMap[id]
                else { continue }

                let playerSpeed = doc.players[playerIndex].speed
                progress += baseIncrement * playerSpeed

                if progress < 1.0 {
                    allDone = false
                } else {
                    progress = 1.0
                }

                playerProgressMap[id] = progress
                doc.players[playerIndex].position = interpolate(along: pathPoints,
                                                                progress: progress)
            }

            if allDone {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    stopAnimation()
                }
            }
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isPlaying = false

        for (id, pos) in originalPositions {
            if let i = doc.players.firstIndex(where: { $0.id == id }) {
                doc.players[i].position = pos
            }
        }
        originalPositions = [:]
        playerArrowMap = [:]
        playerProgressMap = [:]
    }

    private func interpolate(along points: [CGPoint], progress: CGFloat) -> CGPoint {
        guard points.count >= 2 else { return points.first ?? .zero }

        var segments: [CGFloat] = []
        var totalLength: CGFloat = 0
        for i in 0..<points.count - 1 {
            let d = dist(points[i], points[i + 1])
            segments.append(d)
            totalLength += d
        }

        guard totalLength > 0 else { return points.first ?? .zero }

        let target = progress * totalLength
        var accumulated: CGFloat = 0

        for i in 0..<segments.count {
            let segLen = segments[i]
            if accumulated + segLen >= target {
                let localT = (target - accumulated) / segLen
                let a = points[i]
                let b = points[i + 1]
                return CGPoint(
                    x: a.x + (b.x - a.x) * localT,
                    y: a.y + (b.y - a.y) * localT
                )
            }
            accumulated += segLen
        }

        return points.last ?? .zero
    }

    // MARK: - Helpers

    private func movePlayer(id: UUID, to pos: CGPoint) {
        if let i = doc.players.firstIndex(where: { $0.id == id }) {
            doc.players[i].position = pos
        }
    }

    private func clamped(_ p: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: max(24, min(size.width-24, p.x)),
                y: max(24, min(size.height-24, p.y)))
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(b.x-a.x, 2) + pow(b.y-a.y, 2))
    }
}

// MARK: - Speed Preset Button

struct SpeedPresetBtn: View {
    let label: String
    let value: CGFloat
    let current: CGFloat
    let action: () -> Void

    var isActive: Bool { abs(current - value) < 0.05 }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isActive ? .black : .white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? Color.white : Color.white.opacity(0.12))
                )
        }
    }
}
