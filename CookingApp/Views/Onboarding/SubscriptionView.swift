import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var service = RevenueCatService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?

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

    private var weeklyPriceString: String? {
        guard let pkg = annualPackage else { return nil }
        let weekly = pkg.storeProduct.price / Decimal(52)
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = pkg.storeProduct.currencyCode
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        return fmt.string(from: weekly as NSDecimalNumber)
    }

    private var yearlyPriceString: String? {
        annualPackage?.localizedPriceString
    }

    private var subscriptionLengthString: String? {
        guard let period = annualPackage?.storeProduct.subscriptionPeriod else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        var components = DateComponents()
        switch period.unit {
        case .year:  components.year = period.value
        case .month: components.month = period.value
        case .week:  components.weekOfMonth = period.value
        case .day:   components.day = period.value
        @unknown default: return nil
        }
        return formatter.string(from: components)
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

                    // ── Pricing box ─────────────────────────────────────────
                    VStack(spacing: 12) {
                        // Subscription title + length (required by App Store guidelines)
                        if let title = annualPackage?.storeProduct.localizedTitle {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    if let length = subscriptionLengthString {
                                        Text(length)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            Divider()
                        }

                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Try it for free")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                if let weekly = weeklyPriceString {
                                    Text("\(weekly) / week")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if let yearly = yearlyPriceString {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(yearly)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    if let length = subscriptionLengthString {
                                        Text(length)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
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
                Text("Cancel anytime before trial ends. No charge during trial.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                if service.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if annualPackage == nil {
                    VStack(spacing: 12) {
                        Text("Could not load subscription options.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            Task { await service.fetchOfferings() }
                        } label: {
                            Text("Try Again")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                } else {
                    Button {
                        guard let pkg = annualPackage else { return }
                        HapticManager.impact(.medium)
                        Task {
                            isPurchasing = true
                            errorMessage = nil
                            do {
                                try await service.purchase(package: pkg)
                                if trialDays != nil {
                                    NotificationService.shared.scheduleTrialReminder()
                                }
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
                                Text("Try for free")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isPurchasing)
                }

                HStack(spacing: 8) {
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
                    .disabled(isPurchasing)

                    Text("·").foregroundStyle(.quaternary)
                    Link("Privacy Policy", destination: URL(string: "https://gieljurriens.nl/inkgredients/#privacy")!)
                    Text("·").foregroundStyle(.quaternary)
                    Link("Terms of Service", destination: URL(string: "https://gieljurriens.nl/inkgredients/#terms")!)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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
