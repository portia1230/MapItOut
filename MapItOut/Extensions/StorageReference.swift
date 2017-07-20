//
//  StorageReference+Post.swift
//  Makestagram
//
//  Created by Portia Wang on 6/22/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import Foundation
import FirebaseStorage


import Foundation
import FirebaseStorage

extension StorageReference {
    static let dateFormatter = ISO8601DateFormatter()
    
    static func newContactImageReference(key: String) -> StorageReference {
        let uid = User.currentUser.uid
        return Storage.storage().reference().child("images/contacts/\(uid)/\(key).jpg")
    }
}
