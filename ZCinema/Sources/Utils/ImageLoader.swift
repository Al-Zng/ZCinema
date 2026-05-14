import SwiftUI

// MARK: - Async Image with fallback
struct ZCinemaImage: View {
    let url: String
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        if let imageURL = URL(string: url), !url.isEmpty {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            placeholder
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
    
    private var placeholder: some View {
        ZStack {
            Color(white: 0.15)
            Image(systemName: "film")
                .font(.system(size: 30))
                .foregroundColor(Color(white: 0.4))
        }
    }
}

// MARK: - Extensions
extension View {
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .init(x: phase - 0.3, y: 0),
                        endPoint: .init(x: phase + 0.3, y: 0)
                    )
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1.3
                    }
                }
        } else {
            content
        }
    }
}
