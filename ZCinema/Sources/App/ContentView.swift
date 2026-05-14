import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("الرئيسية", systemImage: "house.fill")
                }
                .tag(0)
            
            MoviesView()
                .tabItem {
                    Label("أفلام", systemImage: "film.fill")
                }
                .tag(1)
            
            SeriesView()
                .tabItem {
                    Label("مسلسلات", systemImage: "tv.fill")
                }
                .tag(2)
            
            AnimeView()
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
        .accentColor(Color("AccentRed"))
        .environment(\.layoutDirection, .rightToLeft)
    }
}
