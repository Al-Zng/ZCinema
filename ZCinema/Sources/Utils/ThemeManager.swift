import SwiftUI

class ThemeManager: ObservableObject {
    @Published var accentColor: Color = Color(red: 0.9, green: 0.1, blue: 0.1)
    
    let backgroundColor = Color(red: 0.07, green: 0.07, blue: 0.07)
    let cardBackground = Color(red: 0.13, green: 0.13, blue: 0.13)
    let surfaceColor = Color(red: 0.18, green: 0.18, blue: 0.18)
    let textPrimary = Color.white
    let textSecondary = Color(white: 0.7)
}
