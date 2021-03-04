//
//  ConversationTableViewCell.swift
//  My Messenger
//
//  Created by Mac on 07/02/2021.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {

    @IBOutlet weak var userNamelabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(userName: String, message: String)  {
        self.userNamelabel.text = userName
        self.messageLabel.text = message
    }

}
