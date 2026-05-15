import SwiftUI

struct PosterImage: View {
    let url: String
    var radius: CGFloat = 8

    var body: some View {
        Group {
            if let u = URL(string: url), !url.isEmpty {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        placeholder.overlay(ProgressView().tint(.gray))
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            Color(white: 0.14)
            Image(systemName: "film")
                .font(.system(size: 28))
                .foregroundColor(Color(white: 0.35))
        }
    }
}

// MARK: - Shimmer modifier
struct Shimmer: ViewModifier {
    @State private var x: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.12), .clear],
                        startPoint: .init(x: x, y: 0),
                        endPoint:   .init(x: x + 0.5, y: 0)
                    )
                    .onAppear {
                        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                            x = 1.5
                        }
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}
