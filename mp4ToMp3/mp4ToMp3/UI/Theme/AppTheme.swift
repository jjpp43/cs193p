import SwiftUI

enum AppTheme {
    static let bg = LinearGradient(
        colors: [
            Color(.systemBackground),
            Color(.secondarySystemBackground)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let card = Color(.secondarySystemBackground)
    static let stroke = Color(.separator).opacity(0.35)
}
