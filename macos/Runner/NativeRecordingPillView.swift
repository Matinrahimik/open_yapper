import SwiftUI

/// Recording pill overlay - compact dark design (v2).
/// Rebuild with: ./scripts/rebuild_macos.sh or flutter clean && flutter run -d macos
struct NativeRecordingPillView: View {
    @ObservedObject var pillState: OverlayWindowController.PillState

    var body: some View {
        HStack(spacing: 6) {
            // Status icon
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusColor)

            // Center content: waveform or status text
            if pillState.state == "recording" {
                WaveformView(level: pillState.audioLevel, barColor: Color.white.opacity(0.9))
                    .frame(height: 18)
                    .frame(maxWidth: .infinity)
            } else if pillState.state == "processing" {
                HStack(spacing: 6) {
                    Text("Thinking...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                        .frame(height: 10)
                }
            } else if pillState.state == "success" {
                Text("Pasted")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
            }

            Spacer(minLength: 2)

            // Counter and Esc hint on the right
            if pillState.state == "recording" {
                HStack(spacing: 4) {
                    Text(formatDuration(pillState.duration))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Esc")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            } else if pillState.state == "processing" {
                Text("Esc")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(width: 180, height: 44)
        .background(Capsule().fill(Color.black.opacity(0.75)))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch pillState.state {
        case "success": return Color(red: 1, green: 0.72, blue: 0.48)
        case "processing": return Color(red: 1, green: 0.72, blue: 0.48)
        default: return Color(red: 1, green: 0.71, blue: 0.67)
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
    let barColor: Color
    private let barCount = 10

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor)
                    .frame(width: 3, height: barHeight(for: i))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Center bars tallest, edge bars smallest. Dynamic variation based on level.
    private func barHeight(for index: Int) -> CGFloat {
        let minH: CGFloat = 2
        let maxH: CGFloat = 18
        let norm = CGFloat(Swift.max(0, Swift.min(1, level)))
        let center = Double(barCount - 1) / 2
        let distanceFromCenter = abs(Double(index) - center) / center
        let centerMultiplier = 1.0 - 0.6 * distanceFromCenter
        let variation = pseudoRandom(index: index, level: level)
        let height = minH + (maxH - minH) * norm * CGFloat(centerMultiplier) * (0.8 + 0.4 * variation)
        return Swift.max(minH, Swift.min(maxH, height))
    }

    private func pseudoRandom(index: Int, level: Float) -> CGFloat {
        let quantized = Int(level * 100) % 100
        let seed = (index * 31 + quantized) % 1000
        let v = (seed * 7919 + 1) % 1000
        return CGFloat(v) / 1000
    }
}
