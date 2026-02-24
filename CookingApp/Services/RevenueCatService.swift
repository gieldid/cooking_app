import Foundation
import RevenueCat

@MainActor
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()

    @Published var isPremium = false
    @Published var isCheckingEntitlement = true
    @Published var offerings: Offerings?
    @Published var isLoading = false

    private init() {
        Task {
            await checkEntitlement()
            isCheckingEntitlement = false
        }
    }

    func checkEntitlement() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {}
    }

    func fetchOfferings() async {
        isLoading = true
        defer { isLoading = false }
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {}
    }

    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
    }

    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        isPremium = info.entitlements["premium"]?.isActive == true
    }
}
