import SwiftUI

struct PlayerTokenView: View {
    let token: PlayerToken
    let isSelected: Bool
    let tokenSize: CGFloat
    let onDrag: (CGPoint) -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    @GestureState private var dragOffset: CGSize = .zero

    private var tokenColors: Color {
        token.team == .offense
            ? Color(red: 0.10, green: 0.55, blue: 0.90)
            : Color(red: 0.92, green: 0.25, blue: 0.25)
    }

    private var speedLabel: String {
        String(format: "%.1fx", token.speed)
    }

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .stroke(Color.yellow, lineWidth: tokenSize * 0.08)
                    .frame(width: tokenSize * 1.3, height: tokenSize * 1.3)
            }

            Circle()
                .fill(tokenColor)
                .frame(width: tokenSize, height: tokenSize)
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)

            if token.team == .defense {
                Image(systemName: "xmark")
                    .font(.system(size: tokenSize * 0.38, weight: .black))
                    .foregroundColor(.white)
            } else {
                Text(token.label)
                    .font(.system(size: tokenSize * 0.36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Speed badge (always visible so coach can see at a glance)
            Text(speedLabel)
                .font(.system(size: tokenSize * 0.22, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 3)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .offset(x: 0, y: tokenSize * 0.62)

            if isSelected {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: tokenSize * 0.38))
                        .foregroundColor(.white)
                        .background(Color.red, in: Circle())
                }
                .offset(x: tokenSize * 0.52, y: -tokenSize * 0.52)
            }
        }
        .offset(dragOffset)
        .position(token.position)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in state = value.translation }
                .onEnded { value in
                    onDrag(CGPoint(
                        x: token.position.x + value.translation.width,
                        y: token.position.y + value.translation.height
                    ))
                }
        )
        .onTapGesture(perform: onTap)
    }
}

struct ArrowsOverlay: View {
    let arrows: [PlayArrow]
    let activePoints: [CGPoint]

    var body: some View {
        Canvas { ctx, _ in
            for arrow in arrows {
                drawArrow(ctx: ctx, points: arrow.points,
                          type: arrow.arrowType, color: Color.black)
            }
            if activePoints.count >= 2 {
                drawArrow(ctx: ctx, points: activePoints,
                          type: .straight, color: Color.black.opacity(0.6))
            }
        }
    }

    private func drawArrow(ctx: GraphicsContext, points: [CGPoint],
                           type: PlayArrow.ArrowType, color: Color) {
        guard points.count >= 2 else { return }

        var path = Path()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }

        if type == .dribble {
            ctx.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: 5, dash: [10, 7]))
        } else {
            ctx.stroke(path, with: .color(color), lineWidth: 5)
        }

        let last  = points[points.count - 1]
        let prev  = points[points.count - 2]
        let angle = atan2(last.y - prev.y, last.x - prev.x)

        if type == .screen {
            let perp = angle + .pi / 2
            var bar = Path()
            bar.move(to: CGPoint(x: last.x + cos(perp)*18, y: last.y + sin(perp)*18))
            bar.addLine(to: CGPoint(x: last.x - cos(perp)*18, y: last.y - sin(perp)*18))
            ctx.stroke(bar, with: .color(color), lineWidth: 5)
        } else {
            let a: CGFloat = 0.45
            var head = Path()
            head.move(to: last)
            head.addLine(to: CGPoint(x: last.x - 18*cos(angle-a),
                                     y: last.y - 18*sin(angle-a)))
            head.move(to: last)
            head.addLine(to: CGPoint(x: last.x - 18*cos(angle+a),
                                     y: last.y - 18*sin(angle+a)))
            ctx.stroke(head, with: .color(color), lineWidth: 5)
        }
    }
}
