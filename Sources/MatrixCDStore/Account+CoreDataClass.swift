//
//  Account+CoreDataClass.swift
//  MatrixCDStore
//
//  Created by Finn Behrens on 16.06.22.
//
//

import Foundation
import CoreData

import MatrixCore
import MatrixClient

public class Account: NSManagedObject, MatrixStoreAccountInfo {
    public var name: String {
        get {
            self.name_cd!
        }
        set {
            self.name_cd = newValue
        }
    }
    

    public typealias AccountIdentifier = MatrixFullUserIdentifier
    public var id: AccountIdentifier {
        get {  mxID }
        set { mxID = newValue }
    }
    
    public var mxID: MatrixFullUserIdentifier {
        get {
            MatrixFullUserIdentifier(string: mxid_cd!)!
        }
        set {
            mxid_cd = newValue.FQMXID
        }
    }
    
    public var homeServer: MatrixHomeserver {
        get {
            MatrixHomeserver(string: homeserver_cd!)!
        }
        set {
            homeserver_cd = newValue.string!
        }
    }
    
    public var FQMXID: String {
        get {
            self.mxid_cd!
        }
        @available(*, deprecated, message: "Use ``mxID`` for checked setting")
        set {
            self.mxid_cd = newValue
        }
    }
    
    public var accessToken: String?
}

