//
//  ChatViewController.swift
//  My Messenger
//
//  Created by Mac on 06/02/2021.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage



class ChatViewController: MessagesViewController {
    
    public var otherUserEmail: String?
    public var isNewConversation: Bool = false
    public var conversationId: String?
    public var name: String?
    
    let sender = Sender(photoURL: "", senderId: "", displayName: "Jhon Wick")
    var messages = [Message]() {
        didSet {
            messagesCollectionView.reloadData()
        }
    }
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String, let userName = UserDefaults.standard.value(forKey: "currentUserName") as? String else {
            return nil
        }
        
        return Sender(photoURL: "", senderId: email, displayName: userName)
    }
    
    init(otherEmail: String, name: String) {
        self.otherUserEmail = otherEmail
        self.name = name
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:\(coder) has not been implemented")
    }
    
    public static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long
        dateFormatter.locale = .current
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        messageInputBar.delegate = self
        messageInputBar.inputTextView.placeholder = "Text Here..."
        messageInputBar.shouldManageSendButtonEnabledState = true
        
        setMessageInputBar()
        startListeningForMessages()
        messagesCollectionView.reloadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem()
    }
    
    func setMessageInputBar() {
        let image = UIImage(systemName: "paperclip")!
        let button = InputBarButtonItem(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        button.image = image
        button.onTouchUpInside { (action) in
        }
        button.spacing = .flexible
        button.imageView?.contentMode = .scaleToFill
        let image2 = UIImage(systemName: "camera.fill")!
        let button2 = InputBarButtonItem(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        button2.image = image2
        button2.onTouchUpInside { _ in
            self.cameraTapped()
        }
        button2.imageView?.contentMode = .scaleAspectFill
        messageInputBar.setLeftStackViewWidthConstant(to: 900, animated: false)
        messageInputBar.setStackViewItems([button,button2], forStack: .left, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 50, animated: false)
        
        messageInputBar.leftStackView.alignment = .center //HERE
        messageInputBar.reloadInputViews()
    }
    
    private func cameraTapped() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like a photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            let imgPicker = UIImagePickerController()
            imgPicker.sourceType = .camera
            imgPicker.delegate = self
            imgPicker.allowsEditing = true
            self.present(imgPicker, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Select From Library", style: .default, handler: { _ in
            let imgPicker = UIImagePickerController()
            imgPicker.sourceType = .savedPhotosAlbum
            imgPicker.allowsEditing = true
            imgPicker.delegate = self
            self.present(imgPicker, animated: true, completion: nil)

        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
            actionSheet.dismiss(animated: true, completion: nil)
        }))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
   private func startListeningForMessages()  {
    guard let id = conversationId else {
        return
    }
    
    DatabaseManager.shared.getAllMessagesForConversation(conversationId: id) { (result) in
        switch result {
        case .success(let messagesData):
            guard !messagesData.isEmpty else {
                self.messages.removeAll()
                return
            }
            self.messages = messagesData
        case .failure(.failedToFecth):
            print("failed to fetch")
        }
    }
    }
    
    func createMessageId() -> String? {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Failed to get current user email.")
            return nil
        }
        let mySafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail!)_\(mySafeEmail)_\(dateString)"
        print("New messageID: \(newIdentifier)")
        return newIdentifier
    }

}


extension ChatViewController:  MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, InputBarAccessoryViewDelegate, MessageCellDelegate  {
    
    
    
    func currentSender() -> SenderType {
        var sender: SenderType = self.selfSender!
        
        messages.map { (message)  in
            
                sender = message.sender
  
        }
        
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        
        return messages.count
    }
    
     func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text:  String) {
        messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageId = createMessageId() else {
            return
        }
        
        
        let message = Message(sender: selfSender , messageId: messageId, sentDate: Date(), kind: .text(text))
        print(text)
        self.messages.append(message)
        self.messageInputBar.inputTextView.text = ""
        self.messagesCollectionView.scrollToLastItem()
        DatabaseManager.shared.createNewConversation(otherUserEmail: otherUserEmail!,name: self.name! ,firstMessage: message) { (success) in
                if success {
                   print("message sent")
                    
                }else {
                    print("something went wrong")
                }
            }
        
        
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        var corner: MessageStyle.TailCorner = .bottomRight
        messages.map { (message)  in
            if isFromCurrentSender(message: message){
                corner = .bottomRight
            }else {
                corner = .bottomLeft
            }
        }
        return .bubbleTail(corner, .curved)
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        return isFromCurrentSender(message: message) ? .systemBlue: .green

        
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: .none)
        default:
            break
        }
    }
    
 
}

extension ChatViewController: UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
           
            return
        }
        
        guard let imageData = image.pngData() else {
           
            return
        }
        
        guard let messageId = createMessageId() else {
            return
        }
        
        let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
        StorageManager.shared.uploadMessageImage(withData: imageData, fileName: fileName) { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let urlString):
                print("Upload message Photo: \(urlString)")
                guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else {
                    return
                }
                let media = Media(url: url , image: nil, placeholderImage: placeholder, size: .zero )
                let message = Message(sender: strongSelf.selfSender!, messageId: messageId, sentDate: Date(), kind: .photo(media))
                DatabaseManager.shared.createNewConversation(otherUserEmail: strongSelf.otherUserEmail!, name: strongSelf.name!, firstMessage: message) { (success) in
                    if success {
                        print("photp message sent")
                        strongSelf.messagesCollectionView.scrollToLastItem()
                    }else {
                        print("Failed to send photo message. ")
                    }
                }
            case .failure(let error):
                print("Message photo upload error: \(error.localizedDescription)")
            }
        }
    }
    
    
}
