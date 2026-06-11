import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject private var sub = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    featuresSection
                    productsSection
                    footerSection
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
                .padding(.top, 36)
            Text("TradecraftAI Pro")
                .font(.largeTitle.bold())
            Text("AI-powered tools for trade professionals")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FeatureRow(icon: "camera.fill",                   color: .blue,   text: "Photo Diagnosis — identify faults from photos")
            FeatureRow(icon: "doc.text.fill",                 color: .green,  text: "Smart Quote — AI job estimates in seconds")
            FeatureRow(icon: "mic.fill",                      color: .red,    text: "Voice to Work Order — hands-free documentation")
            FeatureRow(icon: "message.fill",                  color: .purple, text: "Customer Bot — professional client messaging")
            FeatureRow(icon: "wrench.and.screwdriver.fill",   color: .orange, text: "Troubleshoot Guide — step-by-step AI fixes")
        }
        .padding(.horizontal, 28)
    }

    private var productsSection: some View {
        VStack(spacing: 12) {
            if sub.isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if sub.products.isEmpty {
                Text("Unable to load products. Check your connection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                ForEach(sub.products, id: \.id) { product in
                    ProductRow(product: product, isPurchasing: $isPurchasing) {
                        await doPurchase(product)
                    }
                }
            }

            if let msg = errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            Button("Restore Purchases") {
                Task { await sub.restore() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text("7-day free trial. Auto-renews unless cancelled 24 hours before renewal. Cancel anytime in Settings.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Actions

    private func doPurchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        do {
            try await sub.purchase(product)
            if sub.isSubscribed { dismiss() }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
        isPurchasing = false
    }
}

// MARK: - Sub-views

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 26)
            Text(text)
                .font(.subheadline)
        }
    }
}

private struct ProductRow: View {
    let product: Product
    @Binding var isPurchasing: Bool
    let onPurchase: () async -> Void

    private var isYearly: Bool { product.id.contains("yearly") }

    private var monthlyEquivalent: String {
        let perMonth = product.price / 12
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.locale = Locale.current
        return fmt.string(from: perMonth as NSDecimalNumber) ?? ""
    }

    var body: some View {
        Button {
            Task { await onPurchase() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.headline)
                        if isYearly {
                            Text("SAVE 44%")
                                .font(.caption2.bold())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.25))
                                .clipShape(Capsule())
                        }
                    }
                    Text(isYearly ? "\(monthlyEquivalent)/mo · billed annually" : "billed monthly")
                        .font(.caption)
                        .opacity(0.8)
                }
                Spacer()
                if isPurchasing {
                    ProgressView().tint(isYearly ? .white : .orange)
                } else {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(isYearly ? Color.orange : Color(.secondarySystemBackground))
            .foregroundStyle(isYearly ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                if !isYearly {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
            }
        }
        .disabled(isPurchasing)
    }
}
