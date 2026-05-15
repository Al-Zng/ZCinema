import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @EnvironmentObject var scraperService: ScraperService
    
    enum Tab {
        case home, settings
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            HStack {
                Spacer()
                TabButton(icon: "house.fill", title: "الرئيسية", isSelected: selectedTab == .home) {
                    selectedTab = .home
                }
                Spacer()
                TabButton(icon: "gear", title: "الإعدادات", isSelected: selectedTab == .settings) {
                    selectedTab = .settings
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .background(
                Color.black
                    .opacity(0.95)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .red : .gray)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScraperService())
}