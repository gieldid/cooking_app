import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var service = RevenueCatService.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private let features: [(String, String)] = [
        ("fork.knife", "A new personalized recipe every day"),
        ("slider.horizontal.3", "Filters for diet, allergies & difficulty"),
        ("cart", "Auto-generated shopping lists"),
        ("bell.badge", "Smart daily cooking reminders"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 10) {
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                        Text("Start cooking smarter")
                            .font(.title2)
                            .fontWeight(.bold)

                        // Trial badge
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill")
                            Text("3-day free trial included")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 24)

                    // Features
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
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Packages
                    if service.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let packages = service.offerings?.current?.availablePackages, !packages.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(packages, id: \.identifier) { package in
                                OnboardingPackageRow(
                                    package: package,
                                    isSelected: selectedPackage?.identifier == package.identifier
                                ) {
                                    selectedPackage = package
                                }
                            }
                        }
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

            // Bottom CTA — fixed outside scroll
            VStack(spacing: 12) {
                Button {
                    guard let pkg = selectedPackage else { return }
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
                            Text("Start Free Trial")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedPackage == nil ? Color.gray : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedPackage == nil || isPurchasing)

                Button("Restore Purchases") {
                    Task {
                        isPurchasing = true
                        do {
                            try await service.restorePurchases()
                            if service.isPremium {
                                await viewModel.completeOnboarding()
                            }
                        } catch {}
                        isPurchasing = false
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .disabled(isPurchasing)

                Text("Cancel anytime. Billed after trial ends.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(.regularMaterial)
        }
        .task {
            await service.fetchOfferings()
            selectedPackage = service.offerings?.current?.availablePackages.first(where: {
                $0.packageType == .annual
            }) ?? service.offerings?.current?.availablePackages.first
        }
    }
}

private struct OnboardingPackageRow: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void

    private var trialText: String? {
        guard let intro = package.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        let days = Int(intro.subscriptionPeriod.value)
        return "\(days)-day free trial"
    }

    private var isPopular: Bool { package.packageType == .annual }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if isPopular {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    if let trial = trialText {
                        Text(trial)
                            .font(.caption)
                            .foregroundStyle(.accent)
                            .fontWeight(.medium)
                    } else {
                        Text(package.storeProduct.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(package.localizedPriceString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .tint(.primary)
    }
}
