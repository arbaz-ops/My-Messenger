//
//  Conversation.swift
//  My Messenger
//
//  Created by Mac on 25/02/2021.
//

import Foundation


struct Conversation {
    let conversationId: String
    let lastMessage: String
    let lastEdited: String
    let convoOf: String
    let otherUserName: String
    let users: Users
}


struct Users {
    let currentUser: String
    let otherUser: String
}
