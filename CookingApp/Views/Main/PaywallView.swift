import SwiftUI
import RevenueCat

struct PaywallView: View {
    var showDismissButton: Bool = true
    @StateObject private var service = RevenueCatService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private let features = [
        ("fork.knife",          "A new personalised recipe every day"),
        ("slider.horizontal.3", "Advanced filters & preferences"),
        ("bell.badge",          "Smart cooking reminders"),
        ("arrow.clockwise",     "Skip & rediscover recipes"),
    ]

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
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // ── Hero ───────────────────────────────────────────────
                    VStack(spacing: 12) {
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                        if let days = trialDays {
                            Text("\(days)-Day Free Trial")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.accentColor)
                        } else {
                            Text("Inkgredients Premium")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Text("Full access, cancel anytime")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // ── Features ───────────────────────────────────────────
                    VStack(spacing: 14) {
                        ForEach(features, id: \.0) { icon, text in
                            HStack(spacing: 14) {
                                Image(systemName: icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(.accent)
                                    .frame(width: 28)
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

                    // ── CTA ────────────────────────────────────────────────
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
                                    dismiss()
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
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(annualPackage == nil ? Color.gray : Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(annualPackage == nil || isPurchasing)

                        // Monthly breakdown
                        if let monthly = monthlyPriceString, let yearly = yearlyPriceString {
                            Text("\(monthly) / month · billed \(yearly) yearly")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // ── Restore ────────────────────────────────────────────
                    Button {
                        Task {
                            isRestoring = true
                            errorMessage = nil
                            do {
                                try await service.restorePurchases()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isRestoring = false
                        }
                    } label: {
                        Group {
                            if isRestoring {
                                ProgressView()
                            } else {
                                Text("Restore Purchases")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isRestoring)

                    Text("Cancel anytime before trial ends. Subscription auto-renews yearly unless cancelled.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showDismissButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                    }
                }
            }
        }
        .task {
            await service.fetchOfferings()
        }
    }
}
