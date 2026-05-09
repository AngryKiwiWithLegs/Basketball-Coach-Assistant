import SwiftUI

struct PlayDesignerToolbar: View {
    @Binding var selectedTool: ToolMode
    @Binding var selectedArrowType: PlayArrow.ArrowType
    @Binding var isPlaying: Bool
    let canUndo: Bool
    let onUndo: () -> Void
    let onClear: () -> Void
    let onPlayStop: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {

                // App icon
                Image(systemName: "basketball.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)

                Divider()
                    .frame(height: 36)
                    .background(Color.white.opacity(0.15))

                // Main tools (disabled during playback)
                HStack(spacing: 4) {
                    ToolBtn(icon: "cursorarrow",
                            label: "Select",
                            isOn: selectedTool == .select,
                            tint: .white)      { selectedTool = .select }

                    ToolBtn(icon: "person.circle.fill",
                            label: "Offense",
                            isOn: selectedTool == .addOffense,
                            tint: .blue)       { selectedTool = .addOffense }

                    ToolBtn(icon: "xmark.circle.fill",
                            label: "Defense",
                            isOn: selectedTool == .addDefense,
                            tint: .red)        { selectedTool = .addDefense }

                    ToolBtn(icon: "arrow.up.right",
                            label: "Arrow",
                            isOn: selectedTool == .drawArrow,
                            tint: .yellow)     { selectedTool = .drawArrow }

                    ToolBtn(icon: "eraser.fill",
                            label: "Erase",
                            isOn: selectedTool == .erase,
                            tint: .orange)     { selectedTool = .erase }
                }
                .padding(.horizontal, 8)
                .opacity(isPlaying ? 0.35 : 1.0)
                .disabled(isPlaying)

                // Arrow sub-tools
                if selectedTool == .drawArrow && !isPlaying {
                    Divider()
                        .frame(height: 36)
                        .background(Color.white.opacity(0.15))

                    HStack(spacing: 4) {
                        ToolBtn(icon: "arrow.right",
                                label: "Cut",
                                isOn: selectedArrowType == .straight,
                                tint: .yellow) { selectedArrowType = .straight }

                        ToolBtn(icon: "arrow.right.to.line",
                                label: "Dribble",
                                isOn: selectedArrowType == .dribble,
                                tint: .yellow) { selectedArrowType = .dribble }

                        ToolBtn(icon: "minus.square",
                                label: "Screen",
                                isOn: selectedArrowType == .screen,
                                tint: .yellow) { selectedArrowType = .screen }
                    }
                    .padding(.horizontal, 8)
                }

                Spacer()

                Divider()
                    .frame(height: 36)
                    .background(Color.white.opacity(0.15))

                // Play / Stop button
                Button(action: onPlayStop) {
                    HStack(spacing: 6) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(isPlaying ? "Stop" : "Simulate")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isPlaying ? Color.red : Color.green)
                    )
                }
                .padding(.horizontal, 10)

                Divider()
                    .frame(height: 36)
                    .background(Color.white.opacity(0.15))

                // Undo / Clear
                HStack(spacing: 4) {
                    ToolBtn(icon: "arrow.uturn.backward",
                            label: "Undo",
                            isOn: false,
                            tint: canUndo ? .white : .gray) { onUndo() }
                        .disabled(!canUndo || isPlaying)

                    ToolBtn(icon: "trash",
                            label: "Clear",
                            isOn: false,
                            tint: .red) { onClear() }
                        .disabled(isPlaying)
                }
                .padding(.horizontal, 8)
                .opacity(isPlaying ? 0.35 : 1.0)
            }
            .frame(height: 56)
            .background(Color(white: 0.13))
        }
    }
}

private struct ToolBtn: View {
    let icon: String
    let label: String
    let isOn: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(isOn ? .black : tint.opacity(0.85))
            .frame(width: 58, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOn ? tint : Color.white.opacity(0.07))
            )
        }
    }
}
