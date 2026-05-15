import SwiftUI

@main
struct ZCinemaApp: App {
    @StateObject private var scraperService = ScraperService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scraperService)
                .preferredColorScheme(.dark)
        }
    }
}