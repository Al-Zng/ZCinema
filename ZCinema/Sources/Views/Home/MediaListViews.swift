//
//  MediaListViews.swift
//  ZCinema
//
//  Created by User on 2025-01-01.
//

import SwiftUI

// MARK: - Movies Tab
struct MoviesView: View {
    var body: some View {
        MediaListView(mediaType: .movie, title: "أفلام", icon: "film.fill")
    }
}

// MARK: - Series Tab
struct SeriesView: View {
    var body: some View {
        MediaListView(mediaType: .series, title: "مسلسلات", icon: "tv.fill")
    }
}

// MARK: - Anime Tab
struct AnimeView: View {
    var body: some View {
        MediaListView(mediaType: .anime, title: "انمي", icon: "sparkles.tv.fill")
    }
}

// MARK: - Generic Grid List
struct MediaListView: View {
    @StateObject private var vm: MediaListViewModel
    let title: String
    let icon: String
    
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 145), spacing: 10)
    ]
    
    init(mediaType: MediaType, title: String, icon: String) {
        _vm = StateObject(wrappedValue: MediaListViewModel(mediaType: mediaType))
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.07)
                    .ignoresSafeArea()
                
                if vm.isLoading && vm.items.isEmpty {
                    loadingGrid
                } else if let error = vm.error, vm.items.isEmpty {
                    errorView(error)
                } else {
                    gridContent
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .task {
            await vm.fetchInitial()
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    private var gridContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(vm.items) { item in
                    MediaCard(item: item)
                        .onAppear {
                            if item.id == vm.items.last?.id {
                                Task {
                                    await vm.fetchMore()
                                }
                            }
                        }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            
            if vm.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, 20)
            }
            
            Spacer(minLength: 50)
        }
        .refreshable {
            await vm.fetchInitial()
        }
    }
    
    private var loadingGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<12, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundColor(Color(white: 0.35))
            
            Text("فشل التحميل")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task {
                    await vm.fetchInitial()
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.clockwise")
                    Text("إعادة المحاولة")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(red: 0.9, green: 0.1, blue: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Skeleton Card
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.2))
                .frame(height: 160)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.2))
                .frame(height: 14)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.2))
                .frame(width: 50, height: 12)
        }
        .padding(.bottom, 5)
        .redacted(reason: .placeholder)
        .shimmering()
    }
}
