//
//  AccountManager.swift
//  SearchTransportation
//
//  Created by Jonny on 12/31/16.
//  Copyright © 2016 Jonny. All rights reserved.
//

import Foundation

class AccountManager {
    
    static let shared = AccountManager()
    
    private init() {}
    
    enum AccountError: Error {
        case accountNotExisted
        case userNameExisted
        case passwordIncorrect
        case parameterInvalid
        case passwordTooShort
    }
    
    private enum UserDefaultKey: String {
        case accounts
    }
    
    private(set) var accounts = (UserDefaults.standard.value(forKey: UserDefaultKey.accounts.rawValue) as? [[String : Any]] ?? []).flatMap { Account(propertyList: $0) } {
        didSet {
            NotificationCenter.default.post(name: .accountsDidChange, object: nil)
            
            let accounts = self.accounts
            DispatchQueue.global(qos: .utility).async {
                let propertyLists = accounts.map { $0.propertyList }
                UserDefaults.standard.set(propertyLists, forKey: UserDefaultKey.accounts.rawValue)
            }
        }
    }
    
    func isUsernameExisted(_ username: String) -> Bool {
        return accounts.contains { $0.username == username }
    }
    
    func isPasswordValid(_ password: String) -> Bool {
        return password.characters.count >= 3
    }
    
    func register(_ account: Account) throws {
        
        if account.username.isEmpty || account.password.isEmpty {
            throw AccountError.parameterInvalid
        }
        
        if isUsernameExisted(account.username) {
            throw AccountError.userNameExisted
        }
        
        if !isPasswordValid(account.password) {
            throw AccountError.passwordTooShort
        }
        
        accounts.append(account)
    }
    
    func verify(username: String, password: String) throws -> Account {
        
        guard let account = accounts.first(where: { $0.username == username }) else {
            throw AccountError.accountNotExisted
        }
        
        guard password == account.password else {
            throw AccountError.passwordIncorrect
        }
        
        return account
    }
    
    func modifyInfos(for account: Account, newUsername: String, newPassword: String, canSignInViaTouchID: Bool) throws -> Account {
        
        guard let accountIndex = accounts.index(where: { $0.identifier == account.identifier }) else {
            throw AccountError.accountNotExisted
        }
        
        guard !newUsername.isEmpty else {
            throw AccountError.parameterInvalid
        }
        
        guard newUsername == account.username || !isUsernameExisted(newUsername) else {
            throw AccountError.userNameExisted
        }
        
        guard isPasswordValid(newPassword) else {
            throw AccountError.passwordTooShort
        }
        
        var newAccount = accounts[accountIndex]
        newAccount.username = newUsername
        newAccount.password = newPassword
        newAccount.canSignInViaTouchID = canSignInViaTouchID
        
        accounts[accountIndex] = newAccount
        
        return newAccount
    }
    
    func delete(_ account: Account) throws {
        
        guard let indexOfAccountToDelete = accounts.index(where: { $0.identifier == account.identifier }) else {
            throw AccountError.accountNotExisted
        }
        
        accounts.remove(at: indexOfAccountToDelete)
    }
    
    
}


extension Notification.Name {
    static let accountsDidChange = Notification.Name(rawValue: "accountsDidChange")
}

