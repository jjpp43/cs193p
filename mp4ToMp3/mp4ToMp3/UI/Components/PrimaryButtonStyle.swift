import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accentColor.opacity(isDisabled ? 0.35 : (configuration.isPressed ? 0.75 : 1)))
            )
            .foregroundStyle(Color.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
