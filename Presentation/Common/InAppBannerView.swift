import SwiftUI

struct InAppBannerView: View {
    let title: String
    let message: String
    let icon: String
    let onDismiss: () -> Void
    let onShow: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer(minLength: 8)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.blue)
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal, 12)
        .onAppear { onShow?() }
    }
}


