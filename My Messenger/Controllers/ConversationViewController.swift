//
//  ViewController.swift
//  My Messenger
//
//  Created by Mac on 02/02/2021.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD
    
class ConversationViewController: UIViewController {
   
    
    @IBOutlet weak var tableView: UITableView!
    
    var conversations = [Conversation]()
    let spinner = JGProgressHUD(style: .dark)
    
    
    let noResultLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations."
        label.textColor = .red
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.setHidesBackButton(true, animated:true)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        noResultLabel.isHidden = true
        view.addSubview(noResultLabel)
        print(UserDefaults.standard.value(forKey: "currentUserName"))
       
       
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
        startListeningForConvos()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noResultLabel.frame = CGRect(x: (self.view.frame.width + 40)/3, y: self.view.frame.height/3, width: 200, height: 100)
    }
    
    private func validateAuth() {
        if Auth.auth().currentUser == nil {
            let vc = storyboard?.instantiateViewController(identifier: "LoginViewController") as? LoginViewController
            navigationController?.pushViewController(vc!, animated: true)
        }
       
    }
    
    private func startListeningForConvos() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        self.spinner.show(in: view)
        DatabaseManager.shared.getAllConversations(email: safeEmail) {[weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversation):
                guard !conversation.isEmpty else {
                    strongSelf.spinner.dismiss()
                    strongSelf.tableView.isHidden = true
                    strongSelf.noResultLabel.isHidden = false
                    return
                }
                strongSelf.spinner.dismiss()
                strongSelf.tableView.isHidden = false
                strongSelf.noResultLabel.isHidden = true
                strongSelf.conversations = conversation
                strongSelf.tableView.reloadData()
            case .failure(.failedToFecth):
                strongSelf.spinner.dismiss()
                print("something went wrong")
            }
        }
        
        
    }
    
    @IBAction func composeButtonTapped(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(identifier: "NewConversationViewController") as? NewConversationViewController
        vc?.title = "New Conversation"
        navigationController?.pushViewController(vc!, animated: true)
//        navigationController?.hidesBottomBarWhenPushed = true
    }
    
}


extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? ConversationTableViewCell
        cell?.configure(userName: conversations[indexPath.row].otherUserName, message: conversations[indexPath.row].lastMessage)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ChatViewController(otherEmail: conversations[indexPath.row].users.otherUser, name: conversations[indexPath.row].otherUserName)
        vc.conversationId = conversations[indexPath.row].conversationId
        vc.title = conversations[indexPath.row].otherUserName
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}
