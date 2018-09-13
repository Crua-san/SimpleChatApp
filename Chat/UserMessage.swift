//
//  UserMessage.swift
//  Chat
//
//  Created by Maxim Lanskoy on 06.09.2018.
//  Copyright © 2018 Crua Inc. All rights reserved.
//

import Foundation

struct UserMessage {
    var senderId: String!
    var userName: String!
    var userMessage: String!
    var timeStamp: String
    var senderKey: String!
    
    init(senderId: String,
        userName: String,
        userMessage: String,
        timeStamp: String,
        senderKey: String) {
        
        self.senderId = senderId
        self.userName = userName
        self.userMessage = userMessage
        self.timeStamp = timeStamp
        self.senderKey = senderKey
    }
}

struct SenderKey {
    var senderKey: String!
    
    init( senderKey: String) {
        self.senderKey = senderKey
    }
    
}
