//
//  RegisterViewController.swift
//  My Messenger
//
//  Created by Mac on 02/02/2021.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let spinner = JGProgressHUD(style: .dark)
    let textFields = ["First Name", "Last Name", "Email", "Password"]
    private var emailTextField: UITextField?
    private var passwordTextField: UITextField?
    private var firstNameTextField: UITextField?
    private var lastNameTextField: UITextField?
    @IBOutlet weak var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        signupButton.layer.cornerRadius = 5
    }
    
    
    @IBAction func signupTapped(_ sender: Any) {
        register(firstName: firstNameTextField?.text!, lastName: lastNameTextField?.text!, email: emailTextField?.text!, password: passwordTextField?.text!)
    }
    
    private func register(firstName: String?, lastName: String?, email: String?, password: String?) {
        firstNameTextField?.resignFirstResponder()
        lastNameTextField?.resignFirstResponder()
        emailTextField?.resignFirstResponder()
        passwordTextField?.resignFirstResponder()
        
        guard let firstName = firstName, let lastName = lastName ,let email = email, let password = password, !email.isEmpty,!password.isEmpty, !firstName.isEmpty, !lastName.isEmpty,password.count >= 6 else {
            alertUserSignUpError()
            return
        }
        
        DatabaseManager.shared.userExists(with: email) { [weak self] (exists) in
           
            guard let strongSelf = self else {
                return
            }
            if exists {
                strongSelf.alertUserSignUpError(message: "Email already exists.")
                
            }else {
                strongSelf.spinner.show(in: strongSelf.view)
                UserDefaults.standard.setValue(email, forKey: "email")
                
                Auth.auth().createUser(withEmail: email, password: password) {[weak self] (authResult, error) in
                    guard let strongSelf = self else {
                        return
                    }
                    guard let result = authResult, error == nil else {
                        print("Something went wrong.")
                        strongSelf.alertUserSignUpError(message: "\(error!.localizedDescription)")
                        strongSelf.spinner.dismiss()
                        return
                    }
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    let userName = chatUser.firstName + " " + chatUser.lastName
                    UserDefaults.standard.setValue(userName, forKey: "currentUserName")

                    DatabaseManager.shared.insertUser(user: chatUser) { (success) in
                        if success {
                            print("User inserted: \(result.user.email!)")
                            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                            DatabaseManager.shared.getLoggedInUser(email: safeEmail) { (result) in
                                switch result {
                                case .success(let userName):
                                    UserDefaults.standard.setValue(userName, forKey: "currentUserName")
                                case .failure(let error):
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    }
                    strongSelf.spinner.dismiss()
                    strongSelf.navigationController?.popToRootViewController(animated: true)
                    
                }
            }
        }
        
        
        
    }
    
    func alertUserSignUpError( message:String = "Please enter the required Fields to register.")  {
        let alert = UIAlertController(title: "Whoops!", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: .none))
        present(alert, animated: true)
    }
    
}
extension RegisterViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textFields.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? RegisterTextFieldTableViewCell
        cell?.textFieldLabel.text = textFields[indexPath.row]
        cell?.textField.placeholder = textFields[indexPath.row]
        cell?.textField.delegate = self
        if textFields[indexPath.row] == "Email" {
            cell?.textField.tag = 0
        }
        if textFields[indexPath.row] == "Password" {
            cell?.textField.tag = 1
        }
        if textFields[indexPath.row] == "First Name" {
            cell?.textField.tag = 2
        }
        if textFields[indexPath.row] == "Last Name" {
            cell?.textField.tag = 3
        }
        return cell!
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.systemBlue.cgColor
        textField.layer.borderWidth = 1
        if textField.tag == 1 {
            textField.isSecureTextEntry = true
            passwordTextField = textField
        }
        if textField.tag == 0 {
            emailTextField = textField
        }
        if textField.tag == 2 {
            firstNameTextField = textField
        }
        if textField.tag == 3 {
            lastNameTextField = textField
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        textField.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.1).cgColor
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField{
            lastNameTextField?.becomeFirstResponder()
        }else if textField == lastNameTextField {
            emailTextField?.becomeFirstResponder()
        }else if textField == emailTextField {
            passwordTextField?.becomeFirstResponder()
        }
        
        else if textField == passwordTextField {
            register(firstName: firstNameTextField?.text!, lastName: lastNameTextField?.text!, email: emailTextField?.text!, password: passwordTextField?.text!)
            textField.resignFirstResponder()
        }
        return true
    }
    
}
