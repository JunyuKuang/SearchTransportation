//
//  Account.swift
//  SearchTransportation
//
//  Created by Jonny on 12/30/16.
//  Copyright © 2016 Jonny. All rights reserved.
//

import Foundation

struct Account {
    
    var username: String
    var password: String
    var canSignInViaTouchID: Bool
    
    let identifier: UUID
    
    init(username: String, password: String, canSignInViaTouchID: Bool, identifier: UUID = UUID()) {
        self.username = username
        self.password = password
        self.canSignInViaTouchID = canSignInViaTouchID
        self.identifier = identifier
    }
}

extension Account {
    
    init?(propertyList: [String : Any]) {
        
        guard let username = propertyList["username"] as? String,
            let password = propertyList["password"] as? String,
            let canSignInViaTouchID = propertyList["canSignInViaTouchID"] as? Bool,
            let identifier = propertyList["identifier"] as? String,
            let uuid = UUID(uuidString: identifier) else { return nil }
        
        self.username = username
        self.password = password
        self.canSignInViaTouchID = canSignInViaTouchID
        self.identifier = uuid
    }
    
    var propertyList: [String : Any] {
        return [
            "username" : username,
            "password" : password,
            "canSignInViaTouchID" : canSignInViaTouchID,
            "identifier" : identifier.uuidString,
        ]
    }
}

