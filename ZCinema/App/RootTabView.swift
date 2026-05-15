import SwiftUI
import AVFoundation

struct RootTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("الرئيسية", systemImage: "house.fill")
                }
                .tag(0)

            CategoryListView(type: .movie)
                .tabItem {
                    Label("أفلام", systemImage: "film.fill")
                }
                .tag(1)

            CategoryListView(type: .series)
                .tabItem {
                    Label("مسلسلات", systemImage: "tv.fill")
                }
                .tag(2)

            CategoryListView(type: .anime)
                .tabItem {
                    Label("انمي", systemImage: "sparkles.tv.fill")
                }
                .tag(3)

            SearchView()
                .tabItem {
                    Label("بحث", systemImage: "magnifyingglass")
                }
                .tag(4)
        }
        .accentColor(Color(red: 0.9, green: 0.1, blue: 0.1))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
