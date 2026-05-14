import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var featuredItem: MediaItem? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()
                if vm.isLoading && vm.sections.isEmpty {
                    loadingView
                } else if let error = vm.error, vm.sections.isEmpty {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("ZCinema")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.15, blue: 0.15),
                                         Color(red: 0.75, green: 0.05, blue: 0.05)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .task { await vm.fetchHome() }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 28) {
                if let featured = featuredItem ?? vm.sections.first?.items.first {
                    HeroView(item: featured).padding(.top, 8)
                }
                ForEach(vm.sections) { section in
                    HorizontalMediaRow(section: section)
                }
                Spacer(minLength: 50)
            }
        }
        .refreshable { await vm.fetchHome() }
        .onChange(of: vm.sections.count) { _ in
            if featuredItem == nil {
                featuredItem = vm.sections.randomElement()?.items.randomElement()
            }
        }
    }

    private var loadingView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(white: 0.13))
                    .frame(maxWidth: .infinity).frame(height: 480)
                    .shimmer()
                ForEach(0..<4, id: \.self) { _ in SkeletonRow() }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 50)).foregroundColor(Color(white: 0.35))
            Text("تعذّر تحميل المحتوى")
                .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
            Text(message)
                .font(.system(size: 13)).foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button { Task { await vm.fetchHome() } } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("إعادة المحاولة")
                }
                .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                .padding(.horizontal, 28).padding(.vertical, 13)
                .background(Color(red: 0.9, green: 0.1, blue: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Hero
struct HeroView: View {
    let item: MediaItem
    var body: some View {
        NavigationLink(destination: DetailView(item: item)) {
            ZStack(alignment: .bottom) {
                ZCinemaImage(url: item.imageURL, contentMode: .fill, cornerRadius: 0)
                    .frame(maxWidth: .infinity).frame(height: 500).clipped()
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(red:0.07,green:0.07,blue:0.07).opacity(0.5), location: 0.45),
                        .init(color: Color(red:0.07,green:0.07,blue:0.07), location: 1.0)
                    ],
                    startPoint: .top, endPoint: .bottom
                ).frame(height: 500)
                VStack(alignment: .leading, spacing: 12) {
                    if !item.genre.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(item.genre.prefix(3), id: \.self) { g in
                                Text(g).font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(white: 0.75))
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color(white: 0.2).opacity(0.7))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Text(item.title)
                        .font(.system(size: 26, weight: .black)).foregroundColor(.white)
                        .lineLimit(3).multilineTextAlignment(.leading)
                    HStack(spacing: 12) {
                        if !item.year.isEmpty {
                            Text(item.year).font(.system(size: 13)).foregroundColor(Color(white: 0.7))
                        }
                        if !item.quality.isEmpty {
                            Text(item.quality).font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Color(red:0.9,green:0.1,blue:0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(.yellow)
                            Text(item.rating).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                        }
                    }
                    HStack(spacing: 12) {
                        HStack(spacing: 7) {
                            Image(systemName: "play.fill").font(.system(size: 15, weight: .bold))
                            Text("تشغيل").font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 13)
                        .background(.white).clipShape(RoundedRectangle(cornerRadius: 8))

                        HStack(spacing: 7) {
                            Image(systemName: "info.circle").font(.system(size: 15))
                            Text("التفاصيل").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white).padding(.horizontal, 18).padding(.vertical, 13)
                        .background(Color(white: 0.25).opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
