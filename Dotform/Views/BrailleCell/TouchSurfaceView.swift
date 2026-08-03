import SwiftUI
import UIKit

enum TouchLayout {
    case brailleCell
    case leftRight
    case topBottom
    case topMiddleBottom
}

/// Надёжная обработка касаний поверх учебного поля — без конфликтов жестов SwiftUI.
struct TouchSurfaceView: UIViewRepresentable {
    let layout: TouchLayout
    let onZoneEntered: (Int) -> Void

    func makeUIView(context: Context) -> TouchOverlayUIView {
        let view = TouchOverlayUIView()
        view.layout = layout
        view.isMultipleTouchEnabled = false
        view.backgroundColor = .clear
        view.onZoneChanged = onZoneEntered
        return view
    }

    func updateUIView(_ uiView: TouchOverlayUIView, context: Context) {
        uiView.layout = layout
        uiView.onZoneChanged = onZoneEntered
    }
}

final class TouchOverlayUIView: UIView {
    var layout: TouchLayout = .brailleCell
    var onZoneChanged: ((Int) -> Void)?
    private var activeZone: Int?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handle(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handle(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeZone = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeZone = nil
    }

    private func handle(_ touches: Set<UITouch>) {
        guard let point = touches.first?.location(in: self) else { return }
        guard let zone = zoneIndex(at: point) else { return }
        guard zone != activeZone else { return }
        activeZone = zone
        onZoneChanged?(zone)
    }

    private func zoneIndex(at point: CGPoint) -> Int? {
        let width = bounds.width
        let height = bounds.height
        guard width > 0, height > 0 else { return nil }
        guard point.x >= 0, point.y >= 0, point.x <= width, point.y <= height else { return nil }

        switch layout {
        case .brailleCell:
            let column = point.x < width / 2 ? 0 : 1
            let row = min(2, max(0, Int(point.y / (height / 3))))
            return column * 3 + row
        case .leftRight:
            return point.x < width / 2 ? 0 : 1
        case .topBottom:
            return point.y < height / 2 ? 0 : 1
        case .topMiddleBottom:
            if point.y < height / 3 { return 0 }
            if point.y < 2 * height / 3 { return 1 }
            return 2
        }
    }
}

extension BrailleDot {
    static func from(zoneIndex: Int) -> BrailleDot? {
        let mapping: [BrailleDot] = [.dot1, .dot2, .dot3, .dot4, .dot5, .dot6]
        guard zoneIndex >= 0, zoneIndex < mapping.count else { return nil }
        return mapping[zoneIndex]
    }
}

extension SpatialRegion {
    static func from(zoneIndex: Int, layout: TouchLayout) -> SpatialRegion? {
        switch layout {
        case .leftRight:
            return zoneIndex == 0 ? .left : .right
        case .topBottom:
            return zoneIndex == 0 ? .top : .bottom
        case .topMiddleBottom:
            switch zoneIndex {
            case 0: return .top
            case 1: return .middle
            case 2: return .bottom
            default: return nil
            }
        case .brailleCell:
            return nil
        }
    }

    var spokenName: String {
        switch self {
        case .left: return "Слева"
        case .right: return "Справа"
        case .top: return "Верх"
        case .middle: return "Середина"
        case .bottom: return "Низ"
        }
    }
}
