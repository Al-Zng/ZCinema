import SwiftUI

// MARK: - Portrait Media Card (Netflix style)
struct MediaCard: View {
    let item: MediaItem
    var width: CGFloat = 120
    var height: CGFloat = 175
    
    var body: some View {
        NavigationLink(destination: DetailView(item: item)) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    ZCinemaImage(url: item.imageURL)
                        .frame(width: width, height: height)
                    
                    // Type badge
                    Text(item.type.displayName)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(typeColor(item.type))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(6)
                    
                    // Rating badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.yellow)
                                Text(item.rating)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(5)
                        }
                    }
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text(item.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: width, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func typeColor(_ type: MediaType) -> Color {
        switch type {
        case .movie: return Color(red: 0.9, green: 0.1, blue: 0.1)
        case .series: return Color(red: 0.1, green: 0.4, blue: 0.9)
        case .anime: return Color(red: 0.5, green: 0.1, blue: 0.9)
        }
    }
}

// MARK: - Wide Card (for featured/hero)
struct WideMediaCard: View {
    let item: MediaItem
    
    var body: some View {
        NavigationLink(destination: DetailView(item: item)) {
            ZStack(alignment: .bottomLeading) {
                ZCinemaImage(url: item.imageURL, contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if !item.year.isEmpty {
                            Label(item.year, systemImage: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        if !item.quality.isEmpty {
                            Text(item.quality)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.9, green: 0.1, blue: 0.1))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(item.rating)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(14)
            }
            .frame(height: 200)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var moreURL: String = ""
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                .frame(width: 4, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            if !moreURL.isEmpty {
                Text("المزيد")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Horizontal Media Row
struct HorizontalMediaRow: View {
    let section: HomeSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: section.title, moreURL: section.moreURL)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(section.items) { item in
                        MediaCard(item: item)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Loading Skeleton Card
struct SkeletonCard: View {
    var width: CGFloat = 120
    var height: CGFloat = 175
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.15))
                .frame(width: width, height: height)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.15))
                .frame(width: width * 0.8, height: 10)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.12))
                .frame(width: width * 0.5, height: 10)
                .shimmer()
        }
    }
}

struct SkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.15))
                    .frame(width: 120, height: 18)
                    .shimmer()
                Spacer()
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonCard()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
