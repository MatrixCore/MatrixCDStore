import XCTest
import MatrixClient
@testable import MatrixCDStore


@available(swift, introduced: 5.6)
@available(macOS 13, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
final class MatrixCDStoreTests: XCTestCase {
    static var store: MatrixCDStore = MatrixCDStore.preview
    static var didCreatePreview = false
    

    override func setUp() async throws {
        if !Self.didCreatePreview {
            Self.didCreatePreview = true
            try await Self.store.createPreviewAccounts(saveToKeychain: true)
        }
    }
    
    override class func tearDown() {
        Task {
            try await Self.store.cleanupTestKeychain()
        }
    }
    
    func testCDStorePreviewCount() async throws {
        let accounts = try await Self.store.getAccountInfos()
        XCTAssertEqual(accounts.count, 1)
    }
    
    func testStoreFetchAccountInfo() async throws {
        var amir = try await Self.store.getAccountInfo(accountID: .init(localpart: "amir_sanders", domain: "example.com"))
        XCTAssertEqual(amir.name, "amir")
        amir.accessToken = "bar"
        try amir.saveToKeychain(extraKeychainArguments: MatrixCDStore.previewKeychainExtraArgs)
        try amir.loadAccessToken()
        print(amir.accessToken as Any)
    }
    
    func testStoreSaveAccountInfo() async throws {
        let mxID = MatrixFullUserIdentifier(localpart: "rburtt0", domain: "example.com")
        let reilly = try await Self.store.saveAccountInfo(
            mxID,
            name: "rburtt0",
            homeServer: MatrixCDStore.previewHomeServer,
            deviceId: "rburtt0",
            accessToken: "V6kZZUwMwK",
            extraKeychainArguments: MatrixCDStore.previewKeychainExtraArgs
        )
        
        var reilly_cd = try await Self.store.getAccountInfo(accountID: mxID)
        XCTAssertEqual(reilly, reilly_cd)
        //XCTAssertEqual(reilly.name, reilly_cd.name)
        //XCTAssertEqual(reilly.accessToken, reilly_cd.accessToken)
        
        
        try reilly_cd.loadAccessToken(extraKeychainArguments: MatrixCDStore.previewKeychainExtraArgs)
        
        
        addTeardownBlock {
            print("teardown rburtt")
            // Remove reily
            try reilly_cd.deleteFromKeychain(extraKeychainArguments: MatrixCDStore.previewKeychainExtraArgs)
            try await Self.store.deleteAccountInfo(account: reilly_cd)
        }
    }
}
