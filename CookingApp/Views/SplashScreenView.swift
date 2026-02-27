import SwiftUI

struct SplashScreenView: View {
    let onComplete: () -> Void

    // Falling drop
    @State private var dropY: CGFloat = -500
    @State private var dropScaleX: CGFloat = 0.85
    @State private var dropScaleY: CGFloat = 1.35
    @State private var dropOpacity: Double = 1

    // Impact splat
    @State private var splatScale: CGFloat = 0.01
    @State private var splatOpacity: Double = 0

    // Ripple rings — start at tiny scale but with their target opacity so
    // the first animation frame already has them at full opacity then fading out.
    @State private var ring1Scale: CGFloat = 0.01
    @State private var ring1Opacity: Double = 0.75
    @State private var ring2Scale: CGFloat = 0.01
    @State private var ring2Opacity: Double = 0.55
    @State private var ring3Scale: CGFloat = 0.01
    @State private var ring3Opacity: Double = 0.38

    // Content reveal
    @State private var contentOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.82

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            // Ripple rings — horizontal ellipses (2:1) like a drop hitting water
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

            // Ink splat on impact: layered flat ellipses + scatter droplets
            ZStack {
                Ellipse()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 110, height: 55)
                Ellipse()
                    .fill(Color.accentColor.opacity(0.22))
                    .frame(width: 75, height: 37)
                Ellipse()
                    .fill(Color.accentColor.opacity(0.42))
                    .frame(width: 42, height: 21)
                // Scatter droplets
                Circle().fill(Color.accentColor.opacity(0.30)).frame(width: 7,  height: 7 ).offset(x: -42, y: -5 )
                Circle().fill(Color.accentColor.opacity(0.25)).frame(width: 8,  height: 8 ).offset(x:  40, y:  5 )
                Circle().fill(Color.accentColor.opacity(0.20)).frame(width: 6,  height: 6 ).offset(x: -30, y:  19)
                Circle().fill(Color.accentColor.opacity(0.20)).frame(width: 5,  height: 5 ).offset(x:  28, y: -17)
                Circle().fill(Color.accentColor.opacity(0.15)).frame(width: 5,  height: 5 ).offset(x: -48, y:  12)
                Circle().fill(Color.accentColor.opacity(0.15)).frame(width: 4,  height: 4 ).offset(x:  49, y: -10)
            }
            .scaleEffect(splatScale)
            .opacity(splatOpacity)

            // App content — revealed after the splash
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

            // The falling ink drop (rendered on top so it covers everything)
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
        // ── Phase 1: drop falls to centre (0.0 – 0.6 s) ──────────────────
        withAnimation(.easeIn(duration: 0.6)) {
            dropY = 0
        }

        // ── Phase 2: impact at 0.6 s ──────────────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Squash the drop horizontally
            withAnimation(.easeOut(duration: 0.09)) {
                dropScaleX = 2.5
                dropScaleY = 0.22
            }
            // Show splat with bounce overshoot
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                splatScale = 1.0
                splatOpacity = 1.0
            }

            // 0.7 s: fade out drop + splat, trigger ripples
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.22)) {
                    dropOpacity = 0
                    splatOpacity = 0
                    splatScale = 1.7
                }

                // Ring 1 — expands furthest, fastest
                withAnimation(.easeOut(duration: 0.55)) {
                    ring1Scale = 5.5
                    ring1Opacity = 0
                }

                // Ring 2 — slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeOut(duration: 0.65)) {
                        ring2Scale = 6.5
                        ring2Opacity = 0
                    }
                }

                // Ring 3 — slowest, most diffuse
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.easeOut(duration: 0.75)) {
                        ring3Scale = 7.5
                        ring3Opacity = 0
                    }
                }
            }
        }

        // ── Phase 3: reveal content at 1.0 s ─────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                contentOpacity = 1
                contentScale = 1
            }
        }

        // ── Phase 4: dismiss at 3.0 s ─────────────────────────────────────
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete()
        }
    }
}

// MARK: - Ink drop teardrop shape (point at top, round at bottom)

private struct InkDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let topY = rect.minY
        let r = rect.width / 2
        let circleCenter = CGPoint(x: cx, y: rect.height * 0.70)

        // Top point
        path.move(to: CGPoint(x: cx, y: topY))

        // Right side: curve from point down to right edge of the bottom circle
        path.addCurve(
            to: CGPoint(x: cx + r, y: circleCenter.y),
            control1: CGPoint(x: cx + r * 0.5, y: topY + rect.height * 0.2),
            control2: CGPoint(x: cx + r, y: circleCenter.y - rect.height * 0.18)
        )

        // Bottom arc (right → bottom → left)
        path.addArc(
            center: circleCenter,
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: true
        )

        // Left side: curve from left edge of bottom circle back up to top point
        path.addCurve(
            to: CGPoint(x: cx, y: topY),
            control1: CGPoint(x: cx - r, y: circleCenter.y - rect.height * 0.18),
            control2: CGPoint(x: cx - r * 0.5, y: topY + rect.height * 0.2)
        )

        return path
    }
}
