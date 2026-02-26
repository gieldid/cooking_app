import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var service = RevenueCatService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private let features: [(String, String)] = [
        ("fork.knife",        "A new personalised recipe every day"),
        ("slider.horizontal.3", "Filters for diet, allergies & difficulty"),
        ("cart",              "Auto-generated shopping lists"),
        ("bell.badge",        "Smart daily cooking reminders"),
    ]

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
        fmt.locale = pkg.storeProduct.priceLocale
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

                    // ── Features ────────────────────────────────────────────
                    VStack(spacing: 12) {
                        ForEach(features, id: \.0) { icon, text in
                            HStack(spacing: 12) {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.accent)
                                    .frame(width: 26)
                                Text(text)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                    .padding()
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
