import SwiftUI

struct BrailleCellView: View {
    let letter: BrailleLetter?
    let mode: BrailleCellMode
    let selectedDots: Set<BrailleDot>
    let foundDots: Set<BrailleDot>
    let showFilledDots: Bool
    let onDotTouch: (BrailleDot) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                gridBackground(size: geometry.size)

                TouchSurfaceView(layout: .brailleCell) { zoneIndex in
                    guard let dot = BrailleDot.from(zoneIndex: zoneIndex) else { return }
                    onDotTouch(dot)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Брайлевская ячейка")
        .accessibilityHint(mode.accessibilityHint)
    }

    @ViewBuilder
    private func gridBackground(size: CGSize) -> some View {
        let columnWidth = size.width / 2
        let rowHeight = size.height / 3

        ZStack {
            Color(.systemBackground)

            ForEach(BrailleDot.allCases) { dot in
                let frame = CGRect(
                    x: CGFloat(dot.column) * columnWidth,
                    y: CGFloat(dot.row) * rowHeight,
                    width: columnWidth,
                    height: rowHeight
                )

                BrailleDotZone(
                    isFilled: isDotFilled(dot),
                    isSelected: selectedDots.contains(dot),
                    isFound: foundDots.contains(dot),
                    showDot: shouldShowDot(dot)
                )
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .allowsHitTesting(false)
            }
        }
    }

    private func shouldShowDot(_ dot: BrailleDot) -> Bool {
        guard showFilledDots else { return false }
        return isDotFilled(dot) || selectedDots.contains(dot) || foundDots.contains(dot)
    }

    private func isDotFilled(_ dot: BrailleDot) -> Bool {
        guard let letter else { return false }
        return letter.dots.contains(dot)
    }
}

enum BrailleCellMode {
    case explore
    case findDots
    case build
    case sensory

    var accessibilityHint: String {
        switch self {
        case .explore: return "Исследуй зоны пальцем"
        case .findDots: return "Найди точки буквы"
        case .build: return "Собери букву, отмечая точки"
        case .sensory: return "Сенсорное упражнение"
        }
    }
}

private struct BrailleDotZone: View {
    let isFilled: Bool
    let isSelected: Bool
    let isFound: Bool
    let showDot: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(zoneColor)
                .overlay {
                    Rectangle()
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                }

            if showDot {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.9), lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                    .accessibilityHidden(true)
            }
        }
    }

    private var zoneColor: Color {
        if isSelected { return Color.accentColor.opacity(0.15) }
        if isFound { return Color.green.opacity(0.12) }
        return Color(.secondarySystemBackground)
    }
}

#Preview {
    BrailleCellView(
        letter: BrailleAlphabet.mvpLetters[0],
        mode: .explore,
        selectedDots: [],
        foundDots: [],
        showFilledDots: true,
        onDotTouch: { _ in }
    )
}
