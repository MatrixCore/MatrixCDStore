//
//  File.swift
//  
//
//  Created by Finn Behrens on 20.06.22.
//

#if DEBUG

import Foundation
import MatrixClient
import MatrixCore
import CoreData
import Security


@available(swift, introduced: 5.6)
@available(macOS 13, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension MatrixCDStore {
    internal static let previewHomeServer: MatrixHomeserver = MatrixHomeserver(string: "https://matrix.example.com")!
    internal static let previewKeychainExtraArgs: [String: Any] = [
        kSecAttrLabel as String: "dev.matrixcore.access_token.test"
    ]
    
    public func createPreviewAccounts(saveToKeychain: Bool = true) async throws {
        _ = try await self.saveAccountInfo(
            .init(localpart: "amir_sanders", domain: "example.com"),
            name: "amir",
            homeServer: Self.previewHomeServer,
            deviceId: "AMIR1",
            accessToken: "AABBCCDD",
            saveToKeychain: saveToKeychain,
            extraKeychainArguments: Self.previewKeychainExtraArgs
        )
        
    }
    
    public func cleanupTestKeychain() throws {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecAttrLabel as String: "dev.matrixcore.access_token.test"
        ] as [String : Any]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw MatrixCoreError.keychainError(status)
        }
    }
    
}

#endif
