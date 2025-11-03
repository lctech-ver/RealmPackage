//
//  KeychainManager.swift
//  jktalk.ios
//
//  Created by Ver on 2024/11/18.
//

import Foundation
import Security
import RealmSwift

final class KeychainManager {
    
    static let keyTag = "com.jktalk.realm.key"
    
    enum EncryptionError: Error {
        case keyGenerationFailed
        case keyRetrievalFailed
        case encryptionFailed
        case decryptionFailed
        case invalidKeySize
    }
    
    static func generateKey() throws -> Data {
        var keyData = Data(count: 64)
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw EncryptionError.keyGenerationFailed
        }
        
        return keyData
    }
    
    static func storeKey(_ key: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: self.keyTag.data(using: .utf8)!,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keyGenerationFailed
        }
    }
    
    static func retrieveKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: self.keyTag.data(using: .utf8)!,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data,
              keyData.count == 64 else {
            throw EncryptionError.keyRetrievalFailed
        }
        
        return keyData
    }
}
