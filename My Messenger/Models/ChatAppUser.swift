//
//  ChatAppUser.swift
//  My Messenger
//
//  Created by Mac on 03/02/2021.
//

import Foundation


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
    var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
    safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
    return safeEmail
    }
}
