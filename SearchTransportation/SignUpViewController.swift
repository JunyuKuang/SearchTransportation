//
//  SignUpViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 12/31/16.
//  Copyright © 2016 Jonny. All rights reserved.
//

import UIKit
import LocalAuthentication

class SignUpViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Interface Elements
    
    @IBOutlet private var userNameTextField: UITextField!
    
    @IBOutlet private var passwordTextField: UITextField! { didSet { passwordTextField.delegate = self } }
    
    @IBOutlet private var userNameErrorLabel: UILabel! { didSet { userNameErrorLabel.isHidden = true } }
    
    @IBOutlet private var passwordErrorLabel: UILabel! { didSet { passwordErrorLabel.isHidden = true } }
    
    private var doneButtonItem: UIBarButtonItem!
    
    @IBOutlet private var touchIDSwitch: UISwitch! {
        didSet {
            touchIDSwitch.isEnabled = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            touchIDSwitch.isOn = touchIDSwitch.isEnabled
        }
    }
    
    var accountToModify: Account?
    
    var newAccountRegisterHandler: ((Account) -> Void)?
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameTextField.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self, selector: #selector(userNameTextFieldTextDidChange), name: .UITextFieldTextDidChange, object: userNameTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(passwordTextFieldTextDidChange), name: .UITextFieldTextDidChange, object: passwordTextField)
        
        if let accountToModify = accountToModify {
            userNameTextField.text = accountToModify.username
            passwordTextField.text = accountToModify.password
            touchIDSwitch.isOn = accountToModify.canSignInViaTouchID
            
            doneButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(signUpButtonItemDidTap(_:)))
            navigationItem.rightBarButtonItem = doneButtonItem
        } else {
            doneButtonItem = UIBarButtonItem(title: "Sign Up", style: .done, target: self, action: #selector(signUpButtonItemDidTap(_:)))
            navigationItem.rightBarButtonItem = doneButtonItem
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonItemDidTap(_:)))
        }
        
        updateDoneButtonItemState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        userNameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    
    // MARK: - Notification handlers
    
    @objc private func userNameTextFieldTextDidChange() {
        
        if let username = userNameTextField.text, !username.isEmpty {
            if let accountToModify = accountToModify, username == accountToModify.username {
            } else {
                userNameErrorLabel.isHidden = !AccountManager.shared.isUsernameExisted(username)
            }
        } else {
            userNameErrorLabel.isHidden = true
        }
        
        updateDoneButtonItemState()
    }
    
    @objc private func passwordTextFieldTextDidChange() {
        
        if let text = passwordTextField.text, !text.isEmpty {
            passwordErrorLabel.isHidden = AccountManager.shared.isPasswordValid(text)
        } else {
            passwordErrorLabel.isHidden = true
        }
        
        updateDoneButtonItemState()
    }
    
    
    // MARK: - UI Updates
    
    private func updateDoneButtonItemState() {
        
        let username = userNameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let manager = AccountManager.shared
        
        if !username.isEmpty && !password.isEmpty {
            if let accountToModify = accountToModify, username == accountToModify.username {
                doneButtonItem.isEnabled = manager.isPasswordValid(password)
            } else {
                doneButtonItem.isEnabled = !manager.isUsernameExisted(username) && manager.isPasswordValid(password)
            }
        } else {
            doneButtonItem.isEnabled = false
        }
    }
    
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField == passwordTextField else { return true }
        return doneButtonItem.isEnabled
    }
    
    
    // MARK: - Actions
    
    @IBAction private func userNameTextFieldDidEndOnExit(_ sender: UITextField) {
        passwordTextField.becomeFirstResponder()
    }
    
    @IBAction private func passwordTextFieldDidEndOnExit(_ sender: UITextField) {
        completeSignUp()
    }
    
    @objc private func cancelButtonItemDidTap(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func signUpButtonItemDidTap(_ sender: UIBarButtonItem) {
        completeSignUp()
    }
    
    private func completeSignUp() {
        
        let username = userNameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        do {
            let newAccount: Account
            if let accountToModify = accountToModify {
                newAccount = try AccountManager.shared.modifyInfos(for: accountToModify, newUsername: username, newPassword: password, canSignInViaTouchID: touchIDSwitch.isOn)
            } else {
                newAccount = Account(username: username, password: password, canSignInViaTouchID: touchIDSwitch.isOn)
                try AccountManager.shared.register(newAccount)
            }
            newAccountRegisterHandler?(newAccount)
            
            if navigationController!.viewControllers.count > 1 {
                _ = navigationController!.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        } catch {
            updateDoneButtonItemState()
        }
    }
}
