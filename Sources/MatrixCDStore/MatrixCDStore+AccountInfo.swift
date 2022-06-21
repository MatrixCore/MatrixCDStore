//
//  File.swift
//  
//
//  Created by Finn Behrens on 20.06.22.
//

import Foundation
import CoreData
import MatrixClient
import MatrixCore

@available(swift, introduced: 5.6)
@available(macOS 13, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension MatrixCDStore {
    public typealias AccountInfo = Account
    
    public func saveAccountInfo(_ mxID: MatrixFullUserIdentifier, name: String, homeServer: MatrixHomeserver, deviceId: String, accessToken: String?, saveToKeychain: Bool = true, extraKeychainArguments: [String: Any] = [:]) async throws -> AccountInfo {
        let account = AccountInfo(context: backgroundContext)
        account.name = name
        account.mxID = mxID
        account.homeServer = homeServer
        account.deviceID = deviceId
        account.accessToken = accessToken
        
        try backgroundContext.save()
        
        if saveToKeychain {
            try account.saveToKeychain(extraKeychainArguments: extraKeychainArguments)
        }
        return account
    }
    
    func saveAccountInfo(account: AccountInfo) async throws {
        try account.managedObjectContext?.save()
    }
    
    public func getAccountInfo(accountID: AccountInfo.AccountIdentifier) async throws -> AccountInfo {
        let fetchRequest = AccountInfo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(
            format: "mxid_cd == %@", accountID.FQMXID
        )
        
        guard let account = try backgroundContext.fetch(fetchRequest).first else {
            throw MatrixCoreError.missingData
        }
        return account
    }
   
    public func getAccountInfos() async throws -> [AccountInfo] {
        try backgroundContext.fetch(AccountInfo.fetchRequest())
    }
    
    public func deleteAccountInfo(account: AccountInfo) async throws {
        backgroundContext.delete(account)
    }
}
