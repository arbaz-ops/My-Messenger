//
//  ProfileViewController.swift
//  My Messenger
//
//  Created by Mac on 04/02/2021.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
   
    var email: String?
    var userName: String?
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        // Do any additional setup after loading the view.
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getUserName()
        getEmail()
        tableView.reloadData()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getUserName()
        getEmail()
        tableView.reloadData()

    }
    
    func getEmail() {
        if let userEmail = UserDefaults.standard.value(forKey: "email") as? String {
            email = userEmail
        }else {
            email = "No User Email."
        }
        

    }
    
    func getUserName()  {
        if let currentUserName = UserDefaults.standard.value(forKey: "currentUserName") as? String {
            userName = currentUserName
        }else {
            userName = "No User Name."
        }
        

    }
  
    
   
    func createTableHeader() -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width , height: 300))
        let imageView = UIImageView(frame: CGRect(x: (self.view.frame.width-150)/2 , y: 75, width: 150, height: 150))
        
        imageView.image = UIImage(systemName: "person.crop.circle")
        imageView.contentMode = .scaleToFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.image?.withRenderingMode(.alwaysOriginal)
        imageView.layer.cornerRadius = imageView.frame.width/2
        
        headerView.addSubview(imageView)
        return headerView
    }
    
    func alertProfileError(message: String = "Somthing went wrong.")  {
        let alert = UIAlertController(title: "Whoops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: .none))
        present(alert, animated: true, completion: nil)
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? ProfileTableViewCell
        switch indexPath.row {
        case 0:
            cell?.titleLabel.text = "User Name"
            cell?.descriptionLabel.text = self.userName
            cell?.descriptionLabel.numberOfLines = 0
        case 1:
            cell?.titleLabel.text = "Email"
            cell?.descriptionLabel.text = self.email
            cell?.descriptionLabel.numberOfLines = 0
        case 2:
            cell?.titleLabel.text = ""
            cell?.descriptionLabel.text = "Delete Account"
            cell?.descriptionLabel.textColor = .red
            cell?.descriptionLabel.textAlignment = .center
        case 3:
            cell?.titleLabel.text = ""
            cell?.descriptionLabel.text = "Log out"
            cell?.descriptionLabel.textColor = .red
            cell?.descriptionLabel.textAlignment = .center
        default:
            break
        }
        
        return cell!
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            tableView.deselectRow(at: indexPath, animated: true)
        case 1:
            tableView.deselectRow(at: indexPath, animated: true)
        case 2:
            tableView.deselectRow(at: indexPath, animated: true)
            let actionSheet = UIAlertController(title: "Alert", message: "Do you really want to delete your account?", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {[weak self] (_) in
                guard let strongSelf = self else{
                    return
                }
                let user = Auth.auth().currentUser
                guard let email = user?.email else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                DatabaseManager.shared.deleteUser(email: safeEmail) { (success) in
                    if success {
                        user?.delete(completion: { (error) in
                            guard error == nil else {
                                strongSelf.alertProfileError(message: error!.localizedDescription)
                                return
                            }
                            let vc = strongSelf.storyboard?.instantiateViewController(identifier: "LoginViewController") as? LoginViewController
                            strongSelf.navigationController?.pushViewController(vc!, animated: true)
                        })
                    }else{
                        strongSelf.alertProfileError()
                        
                    }
                }
                                
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(actionSheet, animated: true, completion: nil)
        case 3:
            tableView.deselectRow(at: indexPath, animated: true)
            let alertSheet = UIAlertController(title: "Alert", message: "Do you really want to logout?", preferredStyle: .actionSheet)
            alertSheet.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                guard let currentUserEmail = Auth.auth().currentUser?.email else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
                DatabaseManager.shared.changeActiveStatus(email: safeEmail, isActive: false)
                        do {
                            FBSDKLoginKit.LoginManager().logOut()

                            try Auth.auth().signOut()
                            let vc = strongSelf.storyboard?.instantiateViewController(identifier: "LoginViewController") as? LoginViewController
                            strongSelf.navigationController?.pushViewController(vc!, animated: true)
                            UserDefaults.standard.removeObject(forKey: "email")
                        } catch let error {
                            print("Failed to logout due to: \(error.localizedDescription)")
                        }
            }))
            alertSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alertSheet, animated: true, completion: nil)
        default:
            break
        }
        
        
    
    }
    
}
