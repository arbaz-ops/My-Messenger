//
//  RegisterTextFieldTableViewCell.swift
//  My Messenger
//
//  Created by Mac on 03/02/2021.
//

import UIKit

class RegisterTextFieldTableViewCell: UITableViewCell {

    @IBOutlet weak var textFieldLabel: UILabel!
   
    @IBOutlet weak var textField: UITextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textField.font = .systemFont(ofSize: 20)
        textField.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
