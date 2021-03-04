//
//  Database.swift
//  My Messenger
//
//  Created by Mac on 03/02/2021.
//
import UIKit
import Foundation
import FirebaseDatabase
import FirebaseFirestore
import MessageKit

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let ref = Database.database().reference()
    private let db = Firestore.firestore().collection("conversations")
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var name: String?
    
}

extension DatabaseManager {
    
    public func insertUser(user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        
            ref.child("users").child(user.safeEmail).setValue([
                "name": user.firstName + " " + user.lastName,
                "email": user.safeEmail,
                "isActive": false
            ]) { (error, _) in
                self.changeActiveStatus(email: user.safeEmail, isActive: true)
            }
    }
    
    public func userExists(with emailAddress: String, completion: @escaping (Bool) -> Void) {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
         safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        Database.database().reference().child("users").child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                self.changeActiveStatus(email: safeEmail, isActive: true)
                completion(true)
            }else {
                
                completion(false)
            }
        }
    }
    
    
    public func getAllUsers(completion: @escaping (Result<[String: [String: Any]],DatabaseError>) -> Void) {
        ref.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let users = snapshot.value as? [String:[String: Any]] else{
                completion(.failure(.failedToFecth))
                return
            }
            
            completion(.success(users))
        }
    }
    
    public func changeActiveStatus(email: String,isActive:Bool) {
        ref.child("users").child(email).updateChildValues(["isActive": isActive]) { (error, _) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
        }
    }
    
    public func createNewConversation(otherUserEmail: String,name: String,firstMessage: Message, completion: @escaping (Bool) -> Void) {
       
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        

            let messageDate = firstMessage.sentDate
            let dateFormatter = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetedUrlString = mediaItem.url?.absoluteString {
                    message = targetedUrlString
                }
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
        guard let currentUserName = UserDefaults.standard.value(forKey: "currentUserName") as? String else {
            return
        }
        
        let conversationId = "\(safeEmail)_\(otherUserEmail)"
            let messageDetails:[String : Any] = [
                    "date": dateFormatter,
                "type": firstMessage.kind.messageKindString,
                    "message": message,
                    "sender": safeEmail,
                    "reciever": otherUserEmail
                
            ]
        
        
        
        self.db.document(conversationId).collection("chatroom").document(firstMessage.messageId).setData(messageDetails) { (error) in
            guard error == nil else {
                print(error!.localizedDescription)
                completion(false)
                return
            }
            
            self.db.document(conversationId).setData([
                "users": [
                    "\(safeEmail)",
                    "\(otherUserEmail)"
                ],
                "convoOf": safeEmail,
                "otherUserName": name,
                "lastEdited": dateFormatter,
                "lastMessage": message,
                
            ]) { (error) in
                guard error == nil else{
                    print(error!.localizedDescription)
                    completion(false)
                    return
                }
               
                
                self.db.document("\(otherUserEmail)_\(safeEmail)").setData([
                    "users": [
                        "\(otherUserEmail)",
                        "\(safeEmail)"
                    ],
                    "convoOf": otherUserEmail,
                    "otherUserName": currentUserName,
                    "lastEdited": dateFormatter,
                    "lastMessage": message
                    
                ]) { (error) in
                    guard error == nil else {
                        print(error!.localizedDescription)
                        completion(false)
                        return
                    }
                    
                    
                    self.db.whereField("users", isEqualTo: [otherUserEmail,safeEmail]).getDocuments{ (snapshot, error) in
                        guard let documents = snapshot?.documents, error == nil else {
                            print(error!.localizedDescription)
                            completion(false)
                            return
                        }
                        
                        for document in documents {
                            self.db.document(document.documentID).collection("chatroom").document(firstMessage.messageId).setData(messageDetails) { (error) in
                                guard error == nil else {
                                    print(error!.localizedDescription)
                                    completion(false)
                                    return
                                }
                                
                                self.db.document(document.documentID).updateData([
                                    "lastEdited": dateFormatter,
                                    "lastMessage": message
                                ])
                                completion(true)
                                
                            }

                        }
                        
                    }
                }
   
            }
            
        }
        
        
        
    }

    
    func getAllConversations(email: String, completion: @escaping (Result<[Conversation],DatabaseError>) -> Void) {
        self.db.whereField("convoOf", isEqualTo: email).getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let conversations: [Conversation] = documents.compactMap ({ (data)  in
                guard let lastMessage = data["lastMessage"] as? String, let lastEdited = data["lastEdited"] as? String, let users = data["users"] as? [String], let convoOf = data["convoOf"] as? String, let otherUserName = data["otherUserName"] as? String  else {
                    completion(.failure(.failedToFecth))
                    return nil
                }
                
                
                let user = Users(currentUser: users[0], otherUser: users[1])
               
               
                return Conversation(conversationId: data.documentID, lastMessage: lastMessage, lastEdited: lastEdited,convoOf: convoOf, otherUserName: otherUserName, users: user)
            })
            completion(.success(conversations))
            
        }
    }
    
    public func getAllMessagesForConversation(conversationId: String, completion: @escaping (Result<[Message], DatabaseError>) -> Void){
        print(conversationId)
        self.db.document(conversationId).collection("chatroom").addSnapshotListener { (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let messages: [Message] = documents.compactMap { (dictionary)  in
                let data = dictionary.data()
              
                guard let message = data["message"] as? String, let sender = data["sender"] as? String, let dateString = data["date"] as? String, let date = ChatViewController.dateFormatter.date(from: dateString), let type = data["type"] as? String  else {
                    completion(.failure(.failedToFecth))
                    print("cannot fetch")
                    return nil
                }
                
                guard let senderName = UserDefaults.standard.value(forKey: "currentUserName") as? String, let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return nil
                }
                var senderId = ""
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                
                if sender == senderId {
                    senderId = safeEmail
                }else {
                    senderId = ""
                }
                var kind: MessageKind?
                if type  == "photo" {
                    guard let url = URL(string: message), let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }else {
                    kind = .text(message)
                }
                guard let finalKind = kind else {
                    return nil
                }
                return Message(sender: Sender(photoURL: "", senderId: sender, displayName: senderName), messageId: dictionary.documentID, sentDate: date, kind: finalKind)
            }
            
            completion(.success(messages))
            
        }
    }
    
    public func getLoggedInUser(email: String, completion: @escaping (Result<String, DatabaseError>) -> Void) {
        
        
        ref.child("users").child(email).observeSingleEvent(of: .value) { (snapshot) in
            guard let user = snapshot.value as? [String: Any] else {
                print("Failed to get user name")
                completion(.failure(.failedToFecth))
                return
            }
            guard let userName = user["name"] as? String else {
                return
            }
            
            completion(.success(userName))
        }

    }
    
    
    
    public func deleteUser(email:String, completion: @escaping (Bool) -> Void) {
        ref.child("users").child(email).observeSingleEvent(of: .value) {[weak self] (snapshot) in
            guard let stronSelf = self else {
                return
            }
            if snapshot.exists() {
                stronSelf.ref.child("users").child(email).removeValue { (error, _) in
                    guard error == nil else {
                        print(error!.localizedDescription)
                        completion(false)
                        return
                    }
                    completion(true)
                }
            }
        }
    }
    
}

enum DatabaseError: Error {
    case failedToFecth
}
