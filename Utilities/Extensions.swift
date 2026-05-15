import SwiftUI

extension Color {
    static let netflixBlack = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let netflixRed = Color(red: 0.9, green: 0.1, blue: 0.1)
}

extension String {
    func decodedBase64() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func encodeBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}