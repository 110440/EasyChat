//
//  ChatManager.swift
//  coder
//
//  Created by tanson on 16/6/11.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloud
import AVOSCloudIM

let conversationAtt_type = "conversationAttType"

//MARK:- IM Notifycation Const
let IMNotifycationrFleshConversation = "IM_notifycation_recveNewConversation"
let IMNotifycationMakeFriendRequest = "IM_notifycation_recveMakeFriendRequest"
let IMNotifycationRecvNewMessage = "IM_notifycation_recveNewMessage"
let IMNotifycationMessageDelivered = "IM_notifycation_recveMessageDelivered"

//MARK:- ConversationType
enum ConversationType:Int{
    case Group = 0
    case Single
    case MakeFriend
    case Unkonw
}

//MARK:- IMManager

let IM = IMManager.instance

class IMManager:NSObject {
    
    static let instance = IMManager()
    
    var imClient:AVIMClient?
    var dataCache:IMCacheManager = IMCacheManager(userName: AVUser.currentUser().username)
    var currentConversation:AVIMConversation?
    
    var connected:Bool{
        return self.imClient != nil && self.imClient!.status == .Opened
    }
    var netStatue:AVIMClientStatus{
        return self.imClient!.status
    }

    override init(){
        super.init()
    }
    
    func connectToSever(clientId:String,block:(error:NSError?)->Void){
        
        self.imClient = AVIMClient(clientId: clientId)
        self.imClient!.delegate = self
        self.imClient?.openWithCallback({ (succeeded, error) in
            if succeeded{
                print("连接IM成功 clientID:\(clientId)")
                block(error: nil)
            }else{
                self.imClient = nil
                block(error: error)
            }
        })
    }
    
    func disconnect(block:(error:NSError?)->Void){
        self.imClient?.closeWithCallback({ (succeeded, error) in
            if succeeded{
                self.imClient = nil
                block(error: nil)
            }else{
                block(error: error)
            }
        })
    }
    
    //MARK: Conversation
    
    func getConversationFromNet(objIDs:[String],block:(conversation:[AVIMConversation]?,error:NSError?)->Void){

        let q = self.imClient!.conversationQuery()
        q.cachePolicy = .NetworkElseCache
        q.whereKey("objectId", containedIn: objIDs)
        q.findConversationsWithCallback { (objects, error) in
            if error == nil {
                block(conversation:objects.map{ $0 as! AVIMConversation }, error: nil)
            }else{
                block(conversation: nil, error: error)
            }
        }
    }
    
    func getAllGroupConersationFromNet(block:(conversations:[AVIMConversation]?,error:NSError?)->Void){
        let q = self.imClient!.conversationQuery()
        q.whereKey(conversationAtt_type, equalTo: ConversationType.Group.rawValue)
        q.whereKey(kAVIMKeyMember, containedIn: [self.imClient!.clientId])
        q.limit = 1000
        q.cachePolicy = .NetworkElseCache
        q.findConversationsWithCallback { (objects, error) in
            if error == nil{
                block(conversations: objects.map{ $0 as! AVIMConversation } , error: nil)
            }else{
                block(conversations: nil, error: error)
            }
        }
        
    }
    
    //创建新的会话
    private func createConversation(members:[String],type:ConversationType,name:String,block:(conversation:AVIMConversation?,error:NSError?)->Void){
        
        let att = [conversationAtt_type:type.rawValue]
        self.imClient?.createConversationWithName(name, clientIds: members, attributes: att, options: .Unique, callback: { (conversation, error) in
            if error == nil{
                self.updateConversationToCache(conversation)
                block(conversation: conversation, error: nil)
            }else{
                block(conversation: nil, error: error)
            }
        })
    }
    
    func createSingleConversation(clientId:String,name:String,block:(conversation:AVIMConversation?,error:NSError?)->Void){
        if let conversation = self.getConversationByFriendIDFromCache(clientId){
            block(conversation: conversation, error: nil)
            return
        }
        let members:[String] = [self.imClient!.clientId,clientId]
        self.createConversation(members, type: .Single, name: name,block: block)
    }
    
    func createGroupConversation(members:Set<String>,name:String,block:(conversation:AVIMConversation?,error:NSError?)->Void){
        var members = [String]()
        for id in members{
            members.append(id)
        }
        self.createConversation(members, type: .Group, name: name,block: block)
    }
    
    // conversation from cache
    
    func getAllRecentConversationFromCache()->[AVIMConversation]{
        let conversations = self.dataCache.getAllConversation()
        for conversation in conversations{
            let messages = self.dataCache.getMessages(conversation.conversationId, start: 0, limit: 1)
            conversation.lastMessage = messages.first
        }
        return conversations
    }
    
    func deleteConversationFromCache(conversationID:String){
        self.dataCache.deleteConversation(conversationID)
    }
    
    func updateConversationToCache(conversation:AVIMConversation){
        if conversation.conversationType == .MakeFriend{ return }
        if self.dataCache.isConversationInCache(conversation.conversationId){
            self.dataCache.updateConversation(conversation)
        }else{
            self.dataCache.insertConversation(conversation)
        }
        NSNotificationCenter.defaultCenter().postNotificationName(IMNotifycationrFleshConversation, object: nil)
    }
    
    func setCurConversationUnreadCountToZero(){
        self.dataCache.setUnreadCountToZero(self.currentConversation!.conversationId)
        NSNotificationCenter.defaultCenter().postNotificationName(IMNotifycationrFleshConversation, object: nil)
    }
    
    func getConversationByFriendIDFromCache(userID:String)->AVIMConversation?{
        let allConversation = self.getAllRecentConversationFromCache()
        for conversation in allConversation{
            let members = conversation.members as! [String]
            if members.count == 2 && members.contains(userID){
                return conversation
            }
        }
        return nil
    }
    
    
   //MARK: Message
    
//    func sayHiToUser(userID:String,block:(error:NSError?)->Void){
//        self.createSingleConversation(userID, name: "", block: { (conversation, error) in
//            if error == nil{
//                self.currentConversation = conversation
//                block(error: nil)
//                NSNotificationCenter.defaultCenter().postNotificationName(notifycationMsg_openChat, object: nil)
//            }else{
//                block(error: error)
//            }
//        })
//    }
    
    func sendMessageToCurrentConversation(msg:AVIMTextMessage,block:(error:NSError?)->Void){
        guard let conversation = self.currentConversation else { return }
        self.dataCache.appendMessage(conversation.conversationId, msg: msg)
        conversation.sendMessage(msg, callback: { (succeeded, error) in
            if succeeded{
                block(error: nil)
            }else{
                block(error: error)
            }
        })
    }
    
    func sendMessageToCurrentConversation(msg:AVIMTypedMessage,progress:(p:Int)->Void,block:(error:NSError?)->Void){
        guard let conversation = self.currentConversation else { return }
        self.dataCache.appendMessage(conversation.conversationId, msg: msg)
        conversation.sendMessage(msg, progressBlock: { (p) in
            progress(p: p)
        }) { (succeeded, error) in
            if succeeded{
                block(error: nil)
            }else{
                block(error: error)
            }
        }
    }
    
    //发送加好友通知
    func sendMakeFriendRequest(friendClientID:String,block:(error:NSError?)->Void){
        let members:[String] = [self.imClient!.clientId,friendClientID]
        let att = [conversationAtt_type:ConversationType.MakeFriend.rawValue]
        self.imClient?.createConversationWithName("MakeFriend", clientIds: members, attributes: att, options: .None, callback: { (conversation, error) in
            if error == nil{
                //send makeFriend msg
                let msg = AVIMTextMessage(text: "请求加好友", attributes: nil)
                conversation.sendMessage(msg, options: AVIMMessageSendOptionTransient, callback: { (succeeded, error) in
                    if succeeded{
                        block(error: nil)
                    }else{
                        block(error: error)
                    }
                })
            }else{
                block(error: error)
            }
        })
    }
    
    // get history message from net
    func getHistoryMessageFromNet(conversation:AVIMConversation,timestamp:Int64,limit:Int,block:(messages:[AVIMTypedMessage]?,error:NSError?)->Void){
        
        let callback = { (objects:[AnyObject]!,error:NSError!) in
            var messages = [AVIMTypedMessage]()
            if error == nil{
                for obj in objects{
                    if let message = obj as? AVIMTypedMessage{
                        messages.append(message)
                    }
                }
                block(messages: messages, error: nil)
            }else{
                block(messages: nil, error: error)
            }
        }
        
        if timestamp == 0 {
            //conversation.queryMessagesWithLimit(UInt(limit), callback: callback)
            conversation.queryMessagesFromServerWithLimit(UInt(limit), callback: callback)
        }else{
            conversation.queryMessagesBeforeId(nil, timestamp: timestamp, limit:UInt(limit), callback: callback)
        }
    }
    
    func getCurConversationMessages(start:Int,limit:Int)->[AVIMTypedMessage]{
        return self.dataCache.getMessages(self.currentConversation!.conversationId, start: start, limit: limit)
    }
    
}

//

//MARK: IMClient  delegate

extension IMManager:AVIMClientDelegate{

    //func conversation(conversation: AVIMConversation!, didReceiveCommonMessage message: AVIMMessage!) {}
    
    func conversation(conversation: AVIMConversation!, didReceiveTypedMessage message: AVIMTypedMessage!) {
        print("\(#file) \(#line) \(#function)")
        
        if conversation.conversationType == .MakeFriend{
            //make friend msg , no cache
            NSNotificationCenter.defaultCenter().postNotificationName(IMNotifycationMakeFriendRequest, object: nil)
            return
        }
        //1
        self.dataCache.appendMessage(conversation.conversationId, msg: message)
        NSNotificationCenter.defaultCenter().postNotificationName(IMNotifycationRecvNewMessage, object: message)
        
        //2
        self.updateConversationToCache(conversation)
        if self.currentConversation?.conversationId != conversation.conversationId {
            self.dataCache.increaseUnreadCount(conversation.conversationId)
            NSNotificationCenter.defaultCenter().postNotificationName(IMNotifycationrFleshConversation, object: nil)
        }
    }
    
    func conversation(conversation: AVIMConversation!, messageDelivered message: AVIMMessage!) {
        print("\(#file) \(#line) \(#function)")
        NSNotificationCenter.defaultCenter().postNotificationName(IMNotifycationMessageDelivered, object: message)
    }
    
    // 会话成员变动
    func conversation(conversation: AVIMConversation!, membersAdded clientIds: [AnyObject]!, byClientId clientId: String!) {
        print("\(#file) \(#line) \(#function)")
        self.updateConversationToCache(conversation)
    }
    func conversation(conversation: AVIMConversation!, membersRemoved clientIds: [AnyObject]!, byClientId clientId: String!) {
        print("\(#file) \(#line) \(#function)")
        self.updateConversationToCache(conversation)
    }
    func conversation(conversation: AVIMConversation!, kickedByClientId clientId: String!) {
        print("\(#file) \(#line) \(#function)")
        //remove
        self.dataCache.deleteConversation(conversation.conversationId)
        NSNotificationCenter.defaultCenter().postNotificationName(IMNotifycationrFleshConversation, object: nil)
    }
    func conversation(conversation: AVIMConversation!, invitedByClientId clientId: String!) {
        print("\(#file) \(#line) \(#function)")
        self.updateConversationToCache(conversation)
    }
    
    // 其他地方登陆
    func client(client: AVIMClient!, didOfflineWithError error: NSError!) {
        print("\(#file) \(#line) \(#function)")
    }
    
    // 网络状态变化
    func imClientPaused(imClient: AVIMClient!) {
    }
    func imClientResuming(imClient: AVIMClient!) {
    }
    func imClientResumed(imClient: AVIMClient!) {
    }
    
}
