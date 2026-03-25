import SwiftUI

/// A ceremonial dark illustration for Ritual's empty states.
struct RitualEmptyIllustration: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let scale = size / 300

            // Warm black glow
            let glowGradient = Gradient(colors: [
                Theme.goldPrimary.opacity(0.08),
                Color.clear
            ])
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - 120 * scale,
                    y: center.y - 120 * scale,
                    width: 240 * scale,
                    height: 240 * scale
                )),
                with: .radialGradient(
                    glowGradient,
                    center: center,
                    startRadius: 0,
                    endRadius: 120 * scale
                )
            )

            // Decorative circles (golden rings)
            let rings: [(CGPoint, CGFloat, CGFloat, Color)] = [
                (center, 80 * scale, 2 * scale, Theme.goldMuted.opacity(0.2)),
                (center, 60 * scale, 1.5 * scale, Theme.goldMuted.opacity(0.3)),
                (center, 40 * scale, 1 * scale, Theme.goldMuted.opacity(0.4)),
            ]
            for (pos, radius, lineWidth, color) in rings {
                var path = Path()
                path.addEllipse(in: CGRect(
                    x: pos.x - radius,
                    y: pos.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }

            // Flame / candle motif at center
            let flameCenter = CGPoint(x: center.x, y: center.y - 10 * scale)
            let flameScale = 30 * scale

            // Outer flame glow
            context.fill(
                Path(ellipseIn: CGRect(
                    x: flameCenter.x - flameScale * 1.5,
                    y: flameCenter.y - flameScale * 2,
                    width: flameScale * 3,
                    height: flameScale * 3
                )),
                with: .radialGradient(
                    Gradient(colors: [Theme.goldPrimary.opacity(0.15), Color.clear]),
                    center: flameCenter,
                    startRadius: 0,
                    endRadius: flameScale * 2
                )
            )

            // Draw flame shape
            var flamePath = Path()
            flamePath.move(to: CGPoint(x: flameCenter.x, y: flameCenter.y + flameScale * 0.5))
            flamePath.addQuadCurve(
                to: CGPoint(x: flameCenter.x - flameScale * 0.4, y: flameCenter.y - flameScale * 0.2),
                control: CGPoint(x: flameCenter.x - flameScale * 0.5, y: flameCenter.y + flameScale * 0.1)
            )
            flamePath.addQuadCurve(
                to: CGPoint(x: flameCenter.x, y: flameCenter.y - flameScale * 0.9),
                control: CGPoint(x: flameCenter.x - flameScale * 0.3, y: flameCenter.y - flameScale * 0.6)
            )
            flamePath.addQuadCurve(
                to: CGPoint(x: flameCenter.x + flameScale * 0.4, y: flameCenter.y - flameScale * 0.2),
                control: CGPoint(x: flameCenter.x + flameScale * 0.3, y: flameCenter.y - flameScale * 0.6)
            )
            flamePath.addQuadCurve(
                to: CGPoint(x: flameCenter.x, y: flameCenter.y + flameScale * 0.5),
                control: CGPoint(x: flameCenter.x + flameScale * 0.5, y: flameCenter.y + flameScale * 0.1)
            )
            flamePath.closeSubpath()

            context.fill(flamePath, with: .linearGradient(
                Gradient(colors: [Theme.goldPrimary.opacity(0.6), Theme.goldPrimary.opacity(0.3), Theme.goldGlow.opacity(0.5)]),
                startPoint: CGPoint(x: flameCenter.x, y: flameCenter.y + flameScale * 0.5),
                endPoint: CGPoint(x: flameCenter.x, y: flameCenter.y - flameScale)
            ))

            // Small decorative dots (stars)
            let stars: [(CGPoint, CGFloat)] = [
                (CGPoint(x: 40 * scale, y: 50 * scale), 2 * scale),
                (CGPoint(x: 260 * scale, y: 60 * scale), 1.5 * scale),
                (CGPoint(x: 30 * scale, y: 220 * scale), 1 * scale),
                (CGPoint(x: 270 * scale, y: 240 * scale), 2 * scale),
                (CGPoint(x: 100 * scale, y: 30 * scale), 1.5 * scale),
                (CGPoint(x: 200 * scale, y: 25 * scale), 1 * scale),
            ]
            for (pos, radius) in stars {
                var starPath = Path()
                starPath.addEllipse(in: CGRect(
                    x: pos.x - radius,
                    y: pos.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(starPath, with: .color(Theme.goldMuted.opacity(0.3)))
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        RitualEmptyIllustration(size: 220)
    }
}
