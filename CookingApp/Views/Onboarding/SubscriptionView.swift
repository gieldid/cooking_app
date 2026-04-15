import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var service = RevenueCatService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var trialDays: Int? {
        guard let pkg = service.offerings?.current?.availablePackages
                .first(where: { $0.packageType == .annual })
                ?? service.offerings?.current?.availablePackages.first,
              let intro = pkg.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        return Int(intro.subscriptionPeriod.value)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {

                    // ── Hero ────────────────────────────────────────────────
                    VStack(spacing: 14) {
                        Image("ChefMascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)

                        Text("Start cooking smarter")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Full access, cancel anytime")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // ── Trial timeline ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        TrialDayRow(
                            day: "Day 1",
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Fire up your kitchen",
                            subtitle: "Get your first personalised recipe and dive straight in",
                            isLast: false
                        )
                        TrialDayRow(
                            day: "Day 2",
                            icon: "bell.badge.fill",
                            iconColor: .accentColor,
                            title: "We've got your back",
                            subtitle: "A friendly reminder lands before any charge",
                            isLast: false
                        )
                        TrialDayRow(
                            day: "Day 3",
                            icon: "sparkles",
                            iconColor: .purple,
                            title: "Your kitchen, your rules",
                            subtitle: "Cancel freely — or keep cooking and save all year",
                            isLast: true
                        )
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            // ── Fixed bottom CTA ────────────────────────────────────────────
            VStack(spacing: 10) {
                Button {
                    HapticManager.impact(.medium)
                    viewModel.nextPage()
                } label: {
                    let label = trialDays.map { "Start \($0)-Day Free Trial" } ?? "Start Free Trial"
                    Text(label)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button("Restore Purchases") {
                    HapticManager.impact(.light)
                    Task {
                        isPurchasing = true
                        errorMessage = nil
                        do {
                            try await service.restorePurchases()
                            if service.isPremium {
                                await viewModel.completeOnboarding()
                            } else {
                                errorMessage = "No active purchases found."
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isPurchasing = false
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .disabled(isPurchasing)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .background(.regularMaterial)
        }
        .task {
            await service.fetchOfferings()
        }
    }
}

private struct TrialDayRow: View {
    let day: String
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon column with connecting line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(iconColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 36)
                }
            }

            // Text column
            VStack(alignment: .leading, spacing: 3) {
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(iconColor)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 10)

            Spacer()
        }
    }
}
