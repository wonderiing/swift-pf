import Foundation
import Security

// MARK: - Keychain Helper
class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        SecItemDelete(query)
        
        SecItemAdd(query, nil)
    }
    
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        return (result as? Data)
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}

class TokenManager {
    static let shared = TokenManager()
    private init() {}
    
    private let service = "YourAppName"
    private let tokenAccount = "auth_token"
    
    var currentToken: String? {
        get {
            guard let tokenData = KeychainHelper.shared.read(service: service, account: tokenAccount) else { return nil }
            return String(data: tokenData, encoding: .utf8)
        }
        set {
            if let token = newValue, let tokenData = token.data(using: .utf8) {
                KeychainHelper.shared.save(tokenData, service: service, account: tokenAccount)
            } else {
                KeychainHelper.shared.delete(service: service, account: tokenAccount)
            }
        }
    }
    
    func logout() {
        currentToken = nil
    }
}

