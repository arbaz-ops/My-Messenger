//
//  StorageManager.swift
//  My Messenger
//
//  Created by Mac on 02/03/2021.
//

import Foundation
import FirebaseStorage


final class StorageManager {
        static let shared = StorageManager()
    private let storage = Storage.storage()
    
    
    
    
}

extension StorageManager {
    
    public func uploadMessageImage(withData imageData: Data,fileName: String ,completion: @escaping ((Result<String,StorageError>) -> Void)) {
        storage.reference().child("image_messages/\(fileName)").putData(imageData,metadata: nil) { (metadata, error) in
            guard error == nil else {
                print("failed to upload image")
                completion(.failure(.failedToUpload))
                return
            }
            self.storage.reference().child("image_messages/\(fileName)").downloadURL { (url, err) in
                guard err == nil else {
                    print("Failed to download image.")
                    completion(.failure(.failedToDownload))
                    return
                }
                
                guard let urlString = url?.absoluteString else {
                    return
                }
                print("download url returned.\(urlString)")
                completion(.success(urlString))
            }
            
        }
    }
}


enum StorageError: Error {
    case failedToUpload, failedToDownload
}
