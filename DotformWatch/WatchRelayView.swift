import SwiftUI

struct WatchRelayView: View {
    @EnvironmentObject private var bridge: WatchRelayReceiver

    var body: some View {
        VStack(spacing: 8) {
            if let display = bridge.currentDisplay {
                Text(display)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel("Символ \(display)")

                WatchDotsGrid(dots: bridge.currentDots)
                    .frame(height: 70)
            } else {
                Image(systemName: "waveform.path")
                    .font(.largeTitle)
                Text("Ожидание")
                    .font(.headline)
                Text("Сообщения с iPhone")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

private struct WatchDotsGrid: View {
    let dots: Set<Int>

    private let positions: [(Int, Int, Int)] = [
        (1, 0, 0), (4, 1, 0),
        (2, 0, 1), (5, 1, 1),
        (3, 0, 2), (6, 1, 2)
    ]

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / 2
            let cellH = geo.size.height / 3
            ZStack {
                ForEach(positions, id: \.0) { item in
                    Circle()
                        .fill(dots.contains(item.0) ? Color.primary : Color.secondary.opacity(0.25))
                        .frame(width: min(cellW, cellH) * 0.45)
                        .position(
                            x: CGFloat(item.1) * cellW + cellW / 2,
                            y: CGFloat(item.2) * cellH + cellH / 2
                        )
                }
            }
        }
        .accessibilityHidden(true)
    }
}
