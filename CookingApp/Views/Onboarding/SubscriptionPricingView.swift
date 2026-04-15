import SwiftUI
import RevenueCat

struct SubscriptionPricingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var service = RevenueCatService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var annualPackage: Package? {
        service.offerings?.current?.availablePackages
            .first(where: { $0.packageType == .annual })
            ?? service.offerings?.current?.availablePackages.first
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
                        Image("ChefMascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)

                        Text("Your subscription")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 24)

                    // ── Pricing card ────────────────────────────────────────
                    if let yearly = yearlyPriceString {
                        VStack(spacing: 6) {
                            Text(yearly)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("per year")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            if let monthly = monthlyPriceString {
                                Text("\(monthly) / month")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 28)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

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
                                Text("Subscribe")
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

                Text("Cancel anytime.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .background(.regularMaterial)
        }
    }
}
