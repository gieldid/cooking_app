import SwiftUI

struct SplashScreenView: View {
    let onComplete: () -> Void

    // Falling drop
    @State private var dropY: CGFloat    = -500
    @State private var dropScaleX: CGFloat = 0.85
    @State private var dropScaleY: CGFloat = 1.35
    @State private var dropOpacity: Double = 1

    // Ink splat (organic blob)
    @State private var splatScale: CGFloat  = 0.01
    @State private var splatOpacity: Double = 0

    // Scatter drops that fly outward on impact
    @State private var s1: CGSize = .zero
    @State private var s2: CGSize = .zero
    @State private var s3: CGSize = .zero
    @State private var s4: CGSize = .zero
    @State private var s5: CGSize = .zero
    @State private var s6: CGSize = .zero
    @State private var scatterOpacity: Double = 0

    // Ripple rings
    @State private var ring1Scale: CGFloat  = 0.01
    @State private var ring1Opacity: Double = 0.70
    @State private var ring2Scale: CGFloat  = 0.01
    @State private var ring2Opacity: Double = 0.50
    @State private var ring3Scale: CGFloat  = 0.01
    @State private var ring3Opacity: Double = 0.35

    // Content reveal
    @State private var contentOpacity: Double = 0
    @State private var contentScale: CGFloat  = 0.82

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            // ── Ripple rings: horizontal ellipses (2:1) like a real liquid impact ──
            Ellipse()
                .stroke(Color.accentColor, lineWidth: 2.5)
                .frame(width: 80, height: 40)
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)

            Ellipse()
                .stroke(Color.accentColor, lineWidth: 2)
                .frame(width: 80, height: 40)
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)

            Ellipse()
                .stroke(Color.accentColor, lineWidth: 1.5)
                .frame(width: 80, height: 40)
                .scaleEffect(ring3Scale)
                .opacity(ring3Opacity)

            // ── Ink splat: organic spiky flat blob ──────────────────────────────
            SplatBlobShape()
                .fill(Color.accentColor.opacity(0.28))
                .frame(width: 180, height: 90)
                .scaleEffect(splatScale)
                .opacity(splatOpacity)

            // ── Scatter drops that fly outward ──────────────────────────────────
            Group {
                Circle().fill(Color.accentColor.opacity(0.45)).frame(width: 9,  height: 9 ).offset(s1)
                Circle().fill(Color.accentColor.opacity(0.38)).frame(width: 7,  height: 7 ).offset(s2)
                Circle().fill(Color.accentColor.opacity(0.35)).frame(width: 6,  height: 6 ).offset(s3)
                Circle().fill(Color.accentColor.opacity(0.30)).frame(width: 5,  height: 5 ).offset(s4)
                Circle().fill(Color.accentColor.opacity(0.25)).frame(width: 8,  height: 8 ).offset(s5)
                Circle().fill(Color.accentColor.opacity(0.20)).frame(width: 5,  height: 5 ).offset(s6)
            }
            .opacity(scatterOpacity)

            // ── App content revealed after splash ───────────────────────────────
            VStack(spacing: 16) {
                Image("ChefMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .accessibilityHidden(true)

                Text("Inkgredients")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)

                Text("Cook something amazing today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .scaleEffect(contentScale)
            .opacity(contentOpacity)

            // ── Falling ink drop (on top) ────────────────────────────────────────
            InkDropShape()
                .fill(Color.accentColor)
                .frame(width: 22, height: 32)
                .scaleEffect(x: dropScaleX, y: dropScaleY)
                .opacity(dropOpacity)
                .offset(y: dropY)
        }
        .onAppear { runAnimation() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading Inkgredients")
    }

    // MARK: - Animation sequence

    private func runAnimation() {
        // ── Phase 1: drop falls (0.0 – 0.6 s) ────────────────────────────
        withAnimation(.easeIn(duration: 0.6)) {
            dropY = 0
        }

        // ── Phase 2: impact at 0.6 s ──────────────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Squash the drop on impact
            withAnimation(.easeOut(duration: 0.08)) {
                dropScaleX = 2.5
                dropScaleY = 0.22
            }

            // Organic splat bursts in with a spring bounce
            withAnimation(.spring(response: 0.35, dampingFraction: 0.52)) {
                splatScale   = 1.0
                splatOpacity = 1.0
            }

            // Scatter drops fly outward
            withAnimation(.easeOut(duration: 0.45)) {
                s1 = CGSize(width: -72, height: -22)
                s2 = CGSize(width:  80, height:  14)
                s3 = CGSize(width: -38, height:  42)
                s4 = CGSize(width:  52, height: -36)
                s5 = CGSize(width: -88, height:  10)
                s6 = CGSize(width:  68, height: -28)
                scatterOpacity = 1.0
            }

            // Fade drop body
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.15)) {
                    dropOpacity = 0
                }
            }

            // Ripples expand after splat lands (0.18 s after impact)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.6)) {
                    ring1Scale   = 5.5
                    ring1Opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeOut(duration: 0.70)) {
                        ring2Scale   = 6.5
                        ring2Opacity = 0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.easeOut(duration: 0.80)) {
                        ring3Scale   = 7.5
                        ring3Opacity = 0
                    }
                }
            }

            // Splat + scatter linger, then fade (0.55 s after impact)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeOut(duration: 0.35)) {
                    splatOpacity   = 0
                    scatterOpacity = 0
                }
            }
        }

        // ── Phase 3: reveal content at 1.1 s ─────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                contentOpacity = 1
                contentScale   = 1
            }
        }

        // ── Phase 4: dismiss at 3.0 s ─────────────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete()
        }
    }
}

// MARK: - Organic flat ink splat

/// An irregular spiky ellipse — wider than tall — that looks like
/// ink spread flat on a surface after impact.
private struct SplatBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width  / 2
        let ry = rect.height / 2

        // 12 spike angles at irregular spacing
        let angles: [CGFloat] = [0, 28, 55, 82, 115, 148, 178, 210, 238, 268, 298, 330]
            .map { $0 * .pi / 180 }
        // Each spike's reach relative to the ellipse radii
        let ratios: [CGFloat] = [1.20, 0.78, 1.15, 0.82, 1.25, 0.75, 1.18, 0.80, 1.22, 0.72, 1.10, 0.85]
        let valleyRatio: CGFloat = 0.60

        let n = angles.count
        var pts: [CGPoint] = []

        for i in 0..<n {
            let a  = angles[i]
            let sr = ratios[i]
            // Scale x and y separately so spikes stay flat (elliptical)
            pts.append(CGPoint(x: cx + cos(a) * rx * sr,
                               y: cy + sin(a) * ry * sr))

            let nextI = (i + 1) % n
            var na = angles[nextI]
            if na < a { na += 2 * .pi }
            let va = (a + na) / 2
            let vr = (ratios[i] + ratios[nextI]) / 2 * valleyRatio
            pts.append(CGPoint(x: cx + cos(va) * rx * vr,
                               y: cy + sin(va) * ry * vr))
        }

        var path = Path()
        let c = pts.count
        path.move(to: mid(pts[c - 1], pts[0]))
        for i in 0..<c {
            path.addQuadCurve(to:      mid(pts[i], pts[(i + 1) % c]),
                              control: pts[i])
        }
        path.closeSubpath()
        return path
    }

    private func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

// MARK: - Ink drop teardrop (point at top, round at bottom)

private struct InkDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let topY = rect.minY
        let r = rect.width / 2
        let circleCenter = CGPoint(x: cx, y: rect.height * 0.70)

        path.move(to: CGPoint(x: cx, y: topY))
        path.addCurve(
            to:       CGPoint(x: cx + r, y: circleCenter.y),
            control1: CGPoint(x: cx + r * 0.5, y: topY + rect.height * 0.2),
            control2: CGPoint(x: cx + r,        y: circleCenter.y - rect.height * 0.18)
        )
        path.addArc(center:     circleCenter,
                    radius:     r,
                    startAngle: .degrees(0),
                    endAngle:   .degrees(180),
                    clockwise:  true)
        path.addCurve(
            to:       CGPoint(x: cx, y: topY),
            control1: CGPoint(x: cx - r,        y: circleCenter.y - rect.height * 0.18),
            control2: CGPoint(x: cx - r * 0.5,  y: topY + rect.height * 0.2)
        )
        return path
    }
}
