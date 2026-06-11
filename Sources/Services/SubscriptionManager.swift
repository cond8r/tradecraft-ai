import StoreKit
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isSubscribed = false
    @Published var products: [Product] = []
    @Published var isLoading = false

    static let monthlyID = "com.fangduo.tradecraftai.monthly"
    static let yearlyID  = "com.fangduo.tradecraftai.yearly"
    private let productIDs = [monthlyID, yearlyID]

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("StoreKit: failed to load products — \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verified(verification)
            await refreshSubscriptionStatus()
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshSubscriptionStatus()
        } catch {
            print("StoreKit: restore failed — \(error)")
        }
    }

    // MARK: - Status

    func refreshSubscriptionStatus() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, productIDs.contains(tx.productID) {
                active = true
                break
            }
        }
        isSubscribed = active
    }

    // MARK: - Helpers

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await self?.refreshSubscriptionStatus()
                    await tx.finish()
                }
            }
        }
    }

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? { "Purchase verification failed." }
    }
}
