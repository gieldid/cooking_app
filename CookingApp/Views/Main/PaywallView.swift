import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var service = RevenueCatService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private let features = [
        ("sparkles", "Unlimited daily recipes"),
        ("slider.horizontal.3", "Advanced filters & preferences"),
        ("bell.badge", "Smart cooking reminders"),
        ("arrow.clockwise", "Skip & rediscover recipes"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        Text("Inkgredients Premium")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Cook smarter every day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Features
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
                                PackageRow(
                                    package: package,
                                    isSelected: selectedPackage?.identifier == package.identifier
                                ) {
                                    selectedPackage = package
                                }
                            }
                        }
                    } else {
                        Text("No plans available right now.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    // Error
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Purchase button
                    Button {
                        guard let pkg = selectedPackage else { return }
                        Task {
                            isPurchasing = true
                            errorMessage = nil
                            do {
                                try await service.purchase(package: pkg)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isPurchasing = false
                        }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(selectedPackage == nil ? "Select a plan" : "Subscribe")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPackage == nil ? Color.gray : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(selectedPackage == nil || isPurchasing)

                    // Restore
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

                    Text("Subscriptions auto-renew unless cancelled. Lifetime is a one-time purchase.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
        .task {
            await service.fetchOfferings()
            selectedPackage = service.offerings?.current?.availablePackages.first(where: {
                $0.packageType == .annual
            }) ?? service.offerings?.current?.availablePackages.first
        }
    }
}

private struct PackageRow: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void

    private var isPopular: Bool {
        package.packageType == .annual
    }

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
                    Text(package.storeProduct.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
