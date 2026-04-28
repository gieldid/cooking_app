import SwiftUI
import RevenueCat

struct PaywallView: View {
    var showDismissButton: Bool = true
    var onCompletion: (() async -> Void)? = nil
    @StateObject private var service = RevenueCatService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private static let lifetimeDeadline: Date = {
        Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
    }()

    private var isLifetimeAvailable: Bool {
        Date() < Self.lifetimeDeadline
    }

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

    private var lifetimePackage: Package? {
        service.offerings?.current?.availablePackages
            .first(where: { $0.packageType == .lifetime })
    }

    private var activePackage: Package? {
        if isLifetimeAvailable, let lifetime = lifetimePackage {
            return lifetime
        }
        return annualPackage
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
        if onCompletion != nil {
            content
        } else {
            NavigationStack {
                content
            }
        }
    }

    private var content: some View {
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

                    Text("Inkgredients Premium")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(isLifetimeAvailable ? "One-time purchase, yours forever" : "Full access, cancel anytime")
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
                } else if activePackage == nil {
                    VStack(spacing: 12) {
                        Text("Could not load subscription options.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            Task { await service.fetchOfferings() }
                        } label: {
                            Text("Try Again")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                } else {
                    Button {
                        guard let pkg = activePackage else { return }
                        HapticManager.impact(.medium)
                        Task {
                            isPurchasing = true
                            errorMessage = nil
                            do {
                                try await service.purchase(package: pkg)
                                if let onCompletion {
                                    await onCompletion()
                                } else {
                                    dismiss()
                                }
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
                                Text(isLifetimeAvailable ? "Get Lifetime Access" : "Subscribe")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isPurchasing)

                    if isLifetimeAvailable {
                        if let price = lifetimePackage?.localizedPriceString {
                            Text(price)
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("One-time purchase · no subscription")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        if let yearly = yearlyPriceString {
                            Text(yearly + " / year")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        if let monthly = monthlyPriceString {
                            Text("\(monthly) / month · cancel anytime")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                // ── Restore ────────────────────────────────────────────
                Button {
                    HapticManager.impact(.light)
                    Task {
                        isRestoring = true
                        errorMessage = nil
                        do {
                            try await service.restorePurchases()
                            if let onCompletion {
                                await onCompletion()
                            } else {
                                dismiss()
                            }
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

                Text(isLifetimeAvailable
                     ? "One-time purchase. No recurring charges."
                     : "Cancel anytime before trial ends. Subscription auto-renews yearly unless cancelled.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                // ── Legal links ────────────────────────────────────────
                HStack(spacing: 12) {
                    Link("Privacy Policy", destination: URL(string: "https://gieljurriens.nl/inkgredients/#privacy")!)
                    Text("·").foregroundStyle(.quaternary)
                    Link("GDPR", destination: URL(string: "https://gieljurriens.nl/inkgredients/#gdpr")!)
                    Text("·").foregroundStyle(.quaternary)
                    Link("Terms of Service", destination: URL(string: "https://gieljurriens.nl/inkgredients/#terms")!)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showDismissButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
        .task {
            await service.fetchOfferings()
        }
    }
}
