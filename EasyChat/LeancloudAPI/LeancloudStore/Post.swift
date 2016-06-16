//
//  Post.swift
//  coder
//
//  Created by tanson on 16/6/6.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloud


class Post: AVObject, AVSubclassing {
    
    @NSManaged var title:String?
    
    @NSManaged var content: String?
    
    @NSManaged var pictures: [String]?
    
    @NSManaged var author: AVUser?
    
    @NSManaged var comments: [Comment]?
    
    @NSManaged var likes: [AVUser]?
    
    class func parseClassName() -> String! {
        return "Post"
    }
    
    override init() {
        super.init()
    }
    
    override class func initialize() {
        struct one {
            static var onceToken : dispatch_once_t = 0
        }
        dispatch_once(&one.onceToken) {
            Post.registerSubclass()
        }
    }
    
}

extension Post{
    
    func addComment(comment:Comment){
        self.addUniqueObject(comment, forKey: "comments")
    }
    
    func addLike(like:AVUser){
        self.addUniqueObject(like, forKey: "likes")
    }
    
}
