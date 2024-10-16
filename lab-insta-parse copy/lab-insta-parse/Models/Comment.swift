//
//  Comment.swift
//  lab-insta-parse
//
//  Created by Eli Antoine on 10/15/24.
//

import Foundation
import ParseSwift


struct Comment: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own custom properties.
    var text: String?
    var user: User?
    var post: Post?
}
