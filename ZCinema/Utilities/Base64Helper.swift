import Foundation

struct Base64Helper {
    static func decode(_ base64: String) -> String? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func encode(_ string: String) -> String {
        return Data(string.utf8).base64EncodedString()
    }
}