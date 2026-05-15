import SwiftUI

// MARK: - Compact portrait card (used in horizontal rows & grids)
struct MediaCard: View {
    let item: MediaItem
    var width: CGFloat  = 115
    var height: CGFloat = 168

    var body: some View {
        NavigationLink(destination: DetailView(pageURL: item.pageURL, title: item.title)) {
            VStack(alignment: .leading, spacing: 5) {
                ZStack(alignment: .topLeading) {
                    PosterImage(url: item.posterURL)
                        .frame(width: width, height: height)

                    typeBadge
                        .padding(5)

                    // Rating bottom-right
                    if !item.rating.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ratingBadge
                                    .padding(5)
                            }
                        }
                    }
                }
                .frame(width: width, height: height)

                Text(item.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(width: width, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private var typeBadge: some View {
        Text(item.type.displayName)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(typeColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var ratingBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 7))
                .foregroundColor(.yellow)
            Text(item.rating)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var typeColor: Color {
        switch item.type {
        case .movie:  return Color(red: 0.85, green: 0.1, blue: 0.1)
        case .series: return Color(red: 0.1,  green: 0.4, blue: 0.9)
        case .anime:  return Color(red: 0.5,  green: 0.1, blue: 0.85)
        }
    }
}

// MARK: - Skeleton card
struct SkeletonCard: View {
    var width: CGFloat  = 115
    var height: CGFloat = 168

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.16))
                .frame(width: width, height: height)
                .shimmer()

            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.16))
                .frame(width: width * 0.78, height: 10)
                .shimmer()

            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.13))
                .frame(width: width * 0.5, height: 10)
                .shimmer()
        }
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                .frame(width: 4, height: 17)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 14)
    }
}
