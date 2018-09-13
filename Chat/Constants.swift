//
//  Constants.swift
//  TestChat
//
//  Created by Maxim Lanskoy on 05.09.2018.
//  Copyright © 2018 Crua Inc. All rights reserved.
//

import Foundation

import Firebase

let incomingBubbleTableViewCell = "incomingBubbleTableViewCell"
let outcomingTableViewCell = "outcomingTableViewCell"
let messagesLimit: UInt = 10

struct Constants {
    
    struct refs {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("chats")
    }
}


