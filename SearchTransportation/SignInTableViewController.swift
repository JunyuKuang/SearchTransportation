//
//  SignInTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 12/31/16.
//  Copyright © 2016 Jonny. All rights reserved.
//

import UIKit
import LocalAuthentication

class SignInTableViewController: TableViewController {
    
    private enum SegueIdentifier: String {
        case showEntryTableViewController
    }
    
    override var hintForEmptyTable: String {
        return "No Accounts"
    }
    
    private var accounts: [Account] {
        return AccountManager.shared.accounts
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(accountsDidChange), name: .accountsDidChange, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let entryTVC = segue.destination as? EntryTableViewController, let account = sender as? Account else { return }
        entryTVC.account = account
    }
    
    @objc private func accountsDidChange() {
        tableView.reloadData()
    }
    
    private func signInViaPasswordForAccount(at indexPath: IndexPath) {
        
        let selectedAccount = accounts[indexPath.row]
        
        let controller = UIAlertController(title: selectedAccount.username, message: nil, preferredStyle: .alert)
        
        let notificationCenter = NotificationCenter.default
        var notificationTokens = [Any]()
        
        func deselectRow() {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let doneAction = UIAlertAction(title: "Sign In", style: .default) { _ in
            notificationTokens.forEach(notificationCenter.removeObserver)
            
            let userName = selectedAccount.username
            let password = controller.textFields?.first?.text ?? ""
            
            do {
                let verifiedAccount = try AccountManager.shared.verify(username: userName, password: password)
                self.performSegue(withIdentifier: SegueIdentifier.showEntryTableViewController.rawValue, sender: verifiedAccount)
            }
            catch {
                let title: String
                
                switch error {
                case AccountManager.AccountError.passwordIncorrect:
                    title = "Password Incorrect"
                case AccountManager.AccountError.accountNotExisted:
                    title = "Account Not Existed"
                default:
                    title = "Unknown Error"
                }
                
                let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Dismiss", style: .cancel) { _ in deselectRow() })
                self.present(controller, animated: true)
            }
            
        }
        doneAction.isEnabled = false
        controller.addAction(doneAction)
        controller.preferredAction = doneAction
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            notificationTokens.forEach(notificationCenter.removeObserver)
            deselectRow()
        }
        controller.addAction(cancelAction)
        
        controller.addTextField { textField in
            textField.enablesReturnKeyAutomatically = true
            textField.placeholder = "Password"
            notificationTokens.append(notificationCenter.addObserver(forName: .UITextFieldTextDidChange, object: textField, queue: .main) { _ in
                doneAction.isEnabled = !controller.textFields!.contains(where: { ($0.text ?? "").isEmpty })
            })
            textField.returnKeyType = .go
            textField.isSecureTextEntry = true
        }
        
        present(controller, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedAccount = accounts[indexPath.row]
        
        if selectedAccount.canSignInViaTouchID {
            let context = LAContext()
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Sign in \(selectedAccount.username).") { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.performSegue(withIdentifier: SegueIdentifier.showEntryTableViewController.rawValue, sender: selectedAccount)
                        }
                        else if let error = error as? LAError, error.code != .userCancel && error.code != .systemCancel {
                            self.signInViaPasswordForAccount(at: indexPath)
                        }
                        else {
                            tableView.deselectRow(at: indexPath, animated: true)
                        }
                    }
                }
            } else {
                signInViaPasswordForAccount(at: indexPath)
            }
        } else {
            signInViaPasswordForAccount(at: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = accounts.count
        hintLabel.isHidden = count > 0
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
        cell.textLabel?.text = accounts[indexPath.row].username
        return cell
    }
    
    @IBAction func signUp(_ sender: Any) {
        
    }
    
}
