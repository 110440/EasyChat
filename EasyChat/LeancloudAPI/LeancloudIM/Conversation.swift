//
//  conversation.swift
//  coder
//
//  Created by tanson on 16/6/11.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloudIM

private var unreadCountkey: Void?
private var lastMsgKey:Void?

extension AVIMConversation{
    func updateName(name:String,block:()->Void){
        
    }
    
    var unreadCount:Int {
        set{
            objc_setAssociatedObject(self, &unreadCountkey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            return objc_getAssociatedObject(self, &unreadCountkey) as? Int ?? 0
        }
    }
    
    var lastMessage:AVIMTypedMessage? {
        set{
            objc_setAssociatedObject(self, &lastMsgKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            return objc_getAssociatedObject(self, &lastMsgKey) as? AVIMTypedMessage
        }
    }
    
    
    var conversationType:ConversationType{
        get{
            let type = self.attributes[conversationAtt_type] as! Int
            return ConversationType(rawValue: type) ?? .Unkonw
        }
    }
    
    var conversationShowName:String{
        var name = ""
        for m in self.members{
            name += m as! String
            name += " "
        }
        return name
    }
}