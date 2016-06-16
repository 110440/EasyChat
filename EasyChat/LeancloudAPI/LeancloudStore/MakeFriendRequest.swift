//
//  BefriendRequest.swift
//  coder
//
//  Created by tanson on 16/6/11.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloud

enum MakeFriendRequestState:Int{
    case Done = 0
    case Wait
}

class MakeFriendRequest: AVObject, AVSubclassing {
    
    @NSManaged var fromUser:AVUser?
    
    @NSManaged var toUser:String? //userID
    
    @NSManaged var state:NSNumber?
    
    //打招呼
    @NSManaged var helloMsg:String?
    //拒绝
    @NSManaged var refuseMsg:String?
    
    @NSManaged var readed:NSNumber?
    
    
    class func parseClassName() -> String! {
        return "MakeFriendRequest"
    }
    
    override init() {
        super.init()
    }
    
    override class func initialize() {
        struct one {
            static var onceToken : dispatch_once_t = 0
        }
        dispatch_once(&one.onceToken) {
            MakeFriendRequest.registerSubclass()
        }
    }
    
}