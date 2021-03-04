//
//  LoginViewController.swift
//  My Messenger
//
//  Created by Mac on 02/02/2021.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import FBSDKLoginKit


class LoginViewController: UIViewController {
    
    
    private var emailTextField: UITextField?
    private var passwordTextField: UITextField?
    @IBOutlet weak var loginButton: UIButton!
    let textFields = ["Email", "Password"]
    @IBOutlet weak var tableView: UITableView!
    
    let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var fbLoginButton: FBLoginButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated:true);
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.allowsSelection = false
        loginButton.layer.cornerRadius = 5
        fbLoginButton.delegate = self
        fbLoginButton.permissions = ["public_profile", "email"]
        
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @IBAction func signUpTapped(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(identifier: "RegisterViewController") as? RegisterViewController
        navigationController?.pushViewController(vc!, animated: true)
        
    }
    
    
    @IBAction func loginTapped(_ sender: Any) {
        login(email: emailTextField?.text, password: passwordTextField?.text)
        
    }
    
    func login(email: String?, password: String?)  {
        emailTextField?.resignFirstResponder()
        passwordTextField?.resignFirstResponder()
        
        guard let email = emailTextField?.text, let password = passwordTextField?.text, !password.isEmpty, !email.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        spinner.show(in: view)
        DatabaseManager.shared.userExists(with: email) { (exists) in
            if exists {
                
                FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
                    guard let stronSelf = self else {
                        return
                    }
                    
                    let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                    DatabaseManager.shared.getLoggedInUser(email: safeEmail) { (result) in
                        switch result {
                        case .success(let userName):
                            UserDefaults.standard.setValue(userName, forKey: "currentUserName")
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    }
                    UserDefaults.standard.setValue(email, forKey: "email")
                    guard let result = authResult, error == nil else {
                        self?.spinner.dismiss()
                        print("Failed to login.")
                        stronSelf.alertUserLoginError(message: "Failed to login.")
                        
                        return
                    }
                    stronSelf.spinner.dismiss()
                    let user = result.user
                    print("User logged in successfully using: \(user.email!)")
                    
                    stronSelf.navigationController?.popToRootViewController(animated: true)
                }
            }else {
                self.alertUserLoginError(message: "User does not exist.")
                self.spinner.dismiss()
            }
        }
    }
    
    private func alertUserLoginError(message: String = "Please enter the required fields to login"){
        let alert = UIAlertController(title: "Whoops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: .none))
        present(alert, animated: true, completion: nil)
    }
    
}

extension LoginViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? LoginTextFieldsTableViewCell
        cell?.txtFieldLbl.text = textFields[indexPath.row]
        cell?.textField.placeholder = textFields[indexPath.row]
        cell?.textField.delegate = self
        
        
        if textFields[indexPath.row] == "Email" {
            cell?.textField.tag = 0
        }
        if textFields[indexPath.row] == "Password" {
            cell?.textField.tag = 1
        }
        return cell!
    }
    //
    //    func textFieldDidBeginEditing(_ textField: UITextField) {
    //        print(emailTextField?.text)
    //        print(passwordTextField?.text)
    //    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.layer.borderColor = UIColor.systemBlue.cgColor
        textField.layer.borderWidth = 1
        if textField.tag == 1 {
            textField.isSecureTextEntry = true
        }
        if textField.tag == 0 {
            emailTextField = textField
        }
        if textField.tag == 1 {
            passwordTextField = textField
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        textField.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.1).cgColor
        
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField?.becomeFirstResponder()
        }else if textField == passwordTextField {
            login(email: emailTextField?.text, password: passwordTextField?.text)
        }
        return true
    }
    
    
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard let token = result?.token?.tokenString else {
            alertUserLoginError(message: "User failed to login with facebook.")
            return
        }
        let parameters = ["fields": "email, first_name, last_name, picture.type(large)"]
        
        
        let facebookRequest = FBSDKLoginKit.GraphRequest.init(graphPath: "me", parameters: parameters, tokenString: token, version: nil, httpMethod: .get)
        facebookRequest.start {  (connection, result, error) in
            guard let result = result as? [String: Any], error == nil else{
                self.alertUserLoginError()
                return
            }
            print(result)
            guard let email = result["email"] as? String, let first_name = result ["first_name"] as? String, let last_name = result["last_name"] as? String else {
                print("Failed to  get id and name of logged in user.")
                
                return
            }
            
            let chatUser = ChatAppUser(firstName: first_name, lastName: last_name, emailAddress: email )
            
            DatabaseManager.shared.insertUser(user: chatUser) { (success) in
                if success {
                    print("User insert successfully.")
                }
            }
            let userName = first_name + " " + last_name
            UserDefaults.standard.setValue(userName, forKey: "currentUserName")
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            self.spinner.show(in: self.view)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) {[weak self] (authResult, error) in
                guard let strongSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.spinner.dismiss()
                    
                }
                guard let result = authResult, error == nil else {
                    print("Facebook login creadential failed:\(String(describing: error?.localizedDescription))")
                    return
                }
                let user = result.user
                UserDefaults.standard.set(email, forKey: "email")
                print("Successfully Logged in using Facebook \(String(describing: user.email))")
                strongSelf.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    
    
}
