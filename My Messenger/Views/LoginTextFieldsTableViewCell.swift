//
//  LoginTextFieldsTableViewCell.swift
//  My Messenger
//
//  Created by Mac on 03/02/2021.
//

import UIKit



class LoginTextFieldsTableViewCell: UITableViewCell {

    @IBOutlet weak var txtFieldLbl: UILabel!
    @IBOutlet weak var textField: UITextField!
   
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textField.font = .systemFont(ofSize: 20)
        textField.layer.cornerRadius = 5

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }

}

