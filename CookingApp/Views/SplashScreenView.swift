import SwiftUI

struct SplashScreenView: View {
    let onComplete: () -> Void

    // Falling drop
    @State private var dropY: CGFloat      = -500
    @State private var dropScaleX: CGFloat = 0.85
    @State private var dropScaleY: CGFloat = 1.35
    @State private var dropOpacity: Double = 1

    // Main ink splat (organic blob at centre)
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

    // Content reveal — mascot and text fade independently
    @State private var mascotOpacity: Double = 0
    @State private var textOpacity: Double   = 0
    @State private var contentScale: CGFloat = 0.85

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            // ── Secondary splatters scattered around the screen ─────────────
            // Each manages its own spring-in / fade animation via onAppear
            MiniSplatView(delay: 0.68, width: 88,  x: -130, y: -270, rotation: -20)
            MiniSplatView(delay: 0.74, width: 72,  x:  145, y: -225, rotation:  18)
            MiniSplatView(delay: 0.71, width: 80,  x: -158, y:  -45, rotation: -35)
            MiniSplatView(delay: 0.79, width: 68,  x:  152, y:   80, rotation:  12)
            MiniSplatView(delay: 0.82, width: 84,  x: -112, y:  240, rotation: -12)
            MiniSplatView(delay: 0.76, width: 64,  x:  128, y:  255, rotation:  28)

            // ── Main ink splat: organic spiky flat blob at centre ───────────
            SplatBlobShape()
                .fill(Color.accentColor.opacity(0.28))
                .frame(width: 180, height: 90)
                .scaleEffect(splatScale)
                .opacity(splatOpacity)

            // ── Scatter drops that fly outward from impact ──────────────────
            Group {
                Circle().fill(Color.accentColor.opacity(0.45)).frame(width: 9, height: 9).offset(s1)
                Circle().fill(Color.accentColor.opacity(0.38)).frame(width: 7, height: 7).offset(s2)
                Circle().fill(Color.accentColor.opacity(0.35)).frame(width: 6, height: 6).offset(s3)
                Circle().fill(Color.accentColor.opacity(0.30)).frame(width: 5, height: 5).offset(s4)
                Circle().fill(Color.accentColor.opacity(0.25)).frame(width: 8, height: 8).offset(s5)
                Circle().fill(Color.accentColor.opacity(0.20)).frame(width: 5, height: 5).offset(s6)
            }
            .opacity(scatterOpacity)

            // ── App content ─────────────────────────────────────────────────
            VStack(spacing: 16) {
                Image("ChefMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .accessibilityHidden(true)
                    .opacity(mascotOpacity)

                VStack(spacing: 8) {
                    Text("Inkgredients")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)

                    Text("Cook something amazing today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .scaleEffect(contentScale)
                .opacity(textOpacity)
            }

            // ── Falling ink drop (on top) ────────────────────────────────────
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
        // ── Phase 1: drop falls (0.0 – 0.6 s) ─────────────────────────────
        withAnimation(.easeIn(duration: 0.6)) {
            dropY = 0
        }

        // ── Phase 2: impact at 0.6 s ───────────────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Squash the drop on impact
            withAnimation(.easeOut(duration: 0.08)) {
                dropScaleX = 2.5
                dropScaleY = 0.22
            }
            // Main splat springs in with bounce
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
            // Fade the drop body
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.15)) { dropOpacity = 0 }
            }
            // Main splat + scatter fade (0.55 s after impact)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeOut(duration: 0.35)) {
                    splatOpacity   = 0
                    scatterOpacity = 0
                }
            }
        }

        // ── Phase 3: reveal content at 1.1 s ──────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                mascotOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                    textOpacity  = 1
                    contentScale = 1
                }
            }
        }

        // ── Phase 3b: pre-fade text at 2.6 s (mascot stays, ready to hero) ─
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                textOpacity = 0
            }
        }

        // ── Phase 4: dismiss at 3.0 s ──────────────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete()
        }
    }
}

// MARK: - Mini splatter (self-animating)

/// A smaller ink splat that springs in after `delay` seconds then fades out.
/// Positioned at (x, y) offset from screen centre, optionally rotated.
private struct MiniSplatView: View {
    let delay:    Double
    let width:    CGFloat
    let x:        CGFloat
    let y:        CGFloat
    let rotation: Double

    @State private var scale:   CGFloat = 0.01
    @State private var opacity: Double  = 0

    var body: some View {
        SplatBlobShape()
            .fill(Color.accentColor.opacity(0.22))
            .frame(width: width, height: width * 0.5)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: x, y: y)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                        scale   = 1.0
                        opacity = 1.0
                    }
                    // Linger then fade out before content settles
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            opacity = 0
                        }
                    }
                }
            }
    }
}

// MARK: - Organic flat ink splat shape

/// Irregular spiky ellipse — wider than tall — like ink spread on a surface.
private struct SplatBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width  / 2
        let ry = rect.height / 2

        let angles: [CGFloat] = [0, 28, 55, 82, 115, 148, 178, 210, 238, 268, 298, 330]
            .map { $0 * .pi / 180 }
        let ratios: [CGFloat]  = [1.20, 0.78, 1.15, 0.82, 1.25, 0.75, 1.18, 0.80, 1.22, 0.72, 1.10, 0.85]
        let valleyRatio: CGFloat = 0.60

        let n = angles.count
        var pts: [CGPoint] = []
        for i in 0..<n {
            let a = angles[i]; let sr = ratios[i]
            pts.append(CGPoint(x: cx + cos(a) * rx * sr, y: cy + sin(a) * ry * sr))
            let nextI = (i + 1) % n
            var na = angles[nextI]; if na < a { na += 2 * .pi }
            let va = (a + na) / 2
            let vr = (ratios[i] + ratios[nextI]) / 2 * valleyRatio
            pts.append(CGPoint(x: cx + cos(va) * rx * vr, y: cy + sin(va) * ry * vr))
        }

        var path = Path()
        let c = pts.count
        path.move(to: mid(pts[c - 1], pts[0]))
        for i in 0..<c {
            path.addQuadCurve(to: mid(pts[i], pts[(i + 1) % c]), control: pts[i])
        }
        path.closeSubpath()
        return path
    }

    private func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

// MARK: - Ink drop teardrop shape

private struct InkDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX; let topY = rect.minY
        let r = rect.width / 2
        let cc = CGPoint(x: cx, y: rect.height * 0.70)

        path.move(to: CGPoint(x: cx, y: topY))
        path.addCurve(to: CGPoint(x: cx + r, y: cc.y),
                      control1: CGPoint(x: cx + r * 0.5, y: topY + rect.height * 0.2),
                      control2: CGPoint(x: cx + r, y: cc.y - rect.height * 0.18))
        path.addArc(center: cc, radius: r,
                    startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
        path.addCurve(to: CGPoint(x: cx, y: topY),
                      control1: CGPoint(x: cx - r, y: cc.y - rect.height * 0.18),
                      control2: CGPoint(x: cx - r * 0.5, y: topY + rect.height * 0.2))
        return path
    }
}
