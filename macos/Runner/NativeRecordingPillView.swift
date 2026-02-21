import SwiftUI

struct NativeRecordingPillView: View {
    @ObservedObject var pillState: OverlayWindowController.PillState

    var body: some View {
        HStack(spacing: 12) {
            // Status icon with glow
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .blur(radius: 6)
                    .opacity(pillState.state == "recording" ? 1 : 0)
                    .scaleEffect(pillState.state == "recording" ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pillState.state)

                Circle()
                    .fill(statusColor)
                    .frame(width: 36, height: 36)

                Image(systemName: statusIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Center content
            VStack(alignment: .leading, spacing: 3) {
                if pillState.state == "recording" {
                    WaveformView(level: pillState.audioLevel)
                        .frame(height: 22)

                    Text(formatDuration(pillState.duration))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                } else if pillState.state == "processing" {
                    Text("Thinking...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.7)
                        .frame(height: 12)
                } else if pillState.state == "success" {
                    Text("Pasted ✓")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 280, height: 64)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(statusColor.opacity(0.15)))
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(statusColor.opacity(0.4), lineWidth: 1.5))
        .shadow(color: statusColor.opacity(0.3), radius: 16, y: 4)
        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
    }

    private var statusColor: Color {
        switch pillState.state {
        case "success": return .green
        case "processing": return .blue
        default: return .red
        }
    }

    private var statusIcon: String {
        switch pillState.state {
        case "success": return "checkmark"
        case "processing": return "brain.head.profile"
        default: return "mic.fill"
        }
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        String(format: "%d:%02d", Int(d) / 60, Int(d) % 60)
    }
}

struct WaveformView: View {
    let level: Float
    private let barCount = 24

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            HStack(spacing: 1.5) {
                ForEach(0..<barCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 2.5, height: barHeight(i, timeline.date.timeIntervalSinceReferenceDate))
                }
            }
        }
    }

    private func barHeight(_ index: Int, _ time: Double) -> CGFloat {
        let min: CGFloat = 2
        let max: CGFloat = 22
        let norm = CGFloat(Swift.max(0, Swift.min(1, level)))
        let phase = sin(Double(index) * 0.6 + time * 4) + cos(Double(index) * 0.3 + time * 2.5)
        let v = CGFloat(phase * 0.25 + 0.5)
        return Swift.max(min, Swift.min(max, min + (max - min) * norm * v))
    }
}
