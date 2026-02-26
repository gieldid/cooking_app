import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var service = RevenueCatService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    // Yearly package only
    private var annualPackage: Package? {
        service.offerings?.current?.availablePackages
            .first(where: { $0.packageType == .annual })
            ?? service.offerings?.current?.availablePackages.first
    }

    private var trialDays: Int? {
        guard let intro = annualPackage?.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        return Int(intro.subscriptionPeriod.value)
    }

    private var monthlyPriceString: String? {
        guard let pkg = annualPackage else { return nil }
        let monthly = pkg.storeProduct.price / Decimal(12)
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = pkg.storeProduct.currencyCode
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        return fmt.string(from: monthly as NSDecimalNumber)
    }

    private var yearlyPriceString: String? {
        annualPackage?.localizedPriceString
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {

                    // ── Hero ────────────────────────────────────────────────
                    VStack(spacing: 14) {
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                        if let days = trialDays {
                            Text("\(days)-Day Free Trial")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.accentColor)
                        } else {
                            Text("Start cooking smarter")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

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
                if service.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Button {
                        guard let pkg = annualPackage else { return }
                        Task {
                            isPurchasing = true
                            errorMessage = nil
                            do {
                                try await service.purchase(package: pkg)
                                await viewModel.completeOnboarding()
                            } catch {
                                if (error as? ErrorCode) != .purchaseCancelledError {
                                    errorMessage = error.localizedDescription
                                }
                            }
                            isPurchasing = false
                        }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(trialDays != nil ? "Start Free Trial" : "Subscribe")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(annualPackage == nil ? Color.gray : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(annualPackage == nil || isPurchasing)

                    // Monthly price breakdown
                    if let monthly = monthlyPriceString, let yearly = yearlyPriceString {
                        Text("\(monthly) / month · billed \(yearly) yearly")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Button("Restore Purchases") {
                    Task {
                        isPurchasing = true
                        do {
                            try await service.restorePurchases()
                            if service.isPremium { await viewModel.completeOnboarding() }
                        } catch {}
                        isPurchasing = false
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .disabled(isPurchasing)

                Text("Cancel anytime before trial ends. No charge during trial.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
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
