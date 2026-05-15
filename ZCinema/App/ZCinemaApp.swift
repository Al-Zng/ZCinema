import SwiftUI

@main
struct ZCinemaApp: App {
    init() {
        configureAudioSession()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .moviePlayback,
            options: []
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func configureAppearance() {
        let tabBar = UITabBar.appearance()
        tabBar.barTintColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)
        tabBar.unselectedItemTintColor = UIColor.gray

        let nav = UINavigationBar.appearance()
        nav.barTintColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)
        nav.tintColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
    }
}
