import SwiftUI

struct ContentRow: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: URL(string: item.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(Image(systemName: "film"))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 140, height: 200)
            .cornerRadius(8)
            .clipped()
            
            Text(item.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 140)
            
            if let rating = item.rating {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text(rating)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}