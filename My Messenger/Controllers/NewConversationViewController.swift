//
//  NewConversationViewController.swift
//  My Messenger
//
//  Created by Mac on 07/02/2021.
//

import UIKit
import JGProgressHUD


class NewConversationViewController: UIViewController  {

    let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private var result = [String:[String: Any]]()
    private var users = [String:[String: Any]]()
    
    var hasfetched: Bool = false
    
    let noResultLabel: UILabel = {
        let label = UILabel()
        label.text = "No Result Found."
        label.textColor = .red
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.placeholder = "Search here..."
        searchBar.barTintColor = .white
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        noResultLabel.isHidden = true
        view.addSubview(noResultLabel)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noResultLabel.frame = CGRect(x: (self.view.frame.width + 40)/3, y: self.view.frame.height/3, width: 200, height: 100)
    }

}

extension NewConversationViewController: UISearchBarDelegate,UITableViewDelegate, UITableViewDataSource {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else {
            return
        }
        spinner.show(in: view)
        searchUser(query: text)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        spinner.show(in: view)
        searchUser(query: searchText)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? NewConversationTableViewCell
        let userName = result.map { (dictionary)  in
            return dictionary.value["name"] as? String
        }
        cell?.userNameLabel.text = userName[indexPath.row] ??  "sadas"
        return cell!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let userEmail = result.map { (dictionary)  in
            return dictionary.value["email"] as! String
        }
        let userName = result.map { (dictionary)  in
            return dictionary.value["name"] as? String
        }
       
        let vc = ChatViewController(otherEmail: userEmail[indexPath.row], name: userName[indexPath.row]!)
//        guard let userName = result["name"] as? String else {
//            return
//        }
       
        vc.title = userName[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func searchUser(query: String) {
        if hasfetched {
            filterUser(with: query)
        }else {
            DatabaseManager.shared.getAllUsers {[weak self] (result) in

                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let userCollection):
                    strongSelf.hasfetched = true
                    strongSelf.users = userCollection
                    strongSelf.filterUser(with: query)
                case .failure(let error):
                   
                    print(error.localizedDescription)
                }
               
            }
        }
    }
    
    func filterUser(with query: String)  {
        guard hasfetched else {
            return
        }
        spinner.dismiss()
        
        let results: [String:[String: Any]] = users.filter { (dictionary) in
            guard let name = (dictionary.value["name"] as? String)?.lowercased() else {
                return false
            }
            return name.hasPrefix(query.lowercased())
        }
        result = results
        print(result)
        updateUI()
    }
    func updateUI() {
        if result.isEmpty {
            noResultLabel.isHidden = false
            
            tableView.isHidden = true
        }else {
            tableView.isHidden = false
            noResultLabel.isHidden = true
            tableView.reloadData()
        }
    }
}
