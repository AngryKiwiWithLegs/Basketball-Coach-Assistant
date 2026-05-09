import SwiftUI

enum ToolMode {
    case select, addOffense, addDefense, drawArrow, erase
}

enum PlayerTeam {
    case offense, defense
}

struct PlayerToken: Identifiable {
    let id = UUID()
    var position: CGPoint
    var team: PlayerTeam
    var number: Int
    var speed: CGFloat = 1.0    // 0.5 = slow, 1.0 = normal, 2.0 = fast
    var label: String { "\(number)" }
}

struct PlayArrow: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var arrowType: ArrowType

    enum ArrowType {
        case straight, dribble, screen
    }
}

class PlayDocument: ObservableObject {
    @Published var players: [PlayerToken] = []
    @Published var arrows: [PlayArrow] = []

    private var offenseCount = 1
    private var defenseCount = 1

    func addPlayer(at position: CGPoint, team: PlayerTeam) {
        let number = team == .offense ? offenseCount : defenseCount
        if team == .offense { offenseCount += 1 } else { defenseCount += 1 }
        players.append(PlayerToken(position: position, team: team, number: number))
    }

    func removePlayer(id: UUID) {
        players.removeAll { $0.id == id }
    }

    func addArrow(_ arrow: PlayArrow) {
        arrows.append(arrow)
    }

    func removeLastArrow() {
        if !arrows.isEmpty { arrows.removeLast() }
    }

    func clear() {
        players.removeAll()
        arrows.removeAll()
        offenseCount = 1
        defenseCount = 1
    }
}
