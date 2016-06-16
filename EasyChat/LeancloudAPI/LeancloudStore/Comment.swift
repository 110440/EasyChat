//
//  Comment.swift
//  coder
//
//  Created by tanson on 16/6/6.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloud

class Comment:AVObject,AVSubclassing{
    
    @NSManaged var content: String?
    @NSManaged var author: AVUser?
    @NSManaged var toPost: Post?
    
    class func parseClassName() -> String! {
        return "Comment"
    }
    
    override init() {
        super.init()
    }
    
    override class func initialize() {
        struct one {
            static var onceToken : dispatch_once_t = 0
        }
        dispatch_once(&one.onceToken) {
            Comment.registerSubclass()
        }
    }
}