//
//  CacheManager.swift
//  coder
//
//  Created by tanson on 16/6/12.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloudIM

private let conversationTableName = "conversationTabel"

private let F_ID = "ConversationID"
private let F_DATA = "data"
private let F_UNREAD_COUNT = "unreadCount"

private let F_MESSAGE_ID = "messageID"
private let F_MESSAGE_DATA = "messageData"

class IMCacheManager{
    
    var DB:SqliteDB
    init(userName:String){
        self.DB = SqliteDB(name: userName)
        self.DB.createTable(conversationTableName, withColumnNamesAndTypes: [F_ID :.StringVal , F_DATA :.DataVal , F_UNREAD_COUNT:.IntVal ])
    }
    
    //MARK: conversation cache
    
    func isConversationInCache(conversationID:String)->Bool{
        let sql = "SELECT * from \(conversationTableName) where \(F_ID) = '\(conversationID)' Limit 1"
        let (resultSet, err) = self.DB.executeQuery(sql)
        if err == nil {
            if resultSet.count > 0 { return true }
        } else {
            print("sqlite err : \( SqliteError.errorMessageFromCode(err!) )")
        }
        return false
    }
    
    
    func insertConversation(conversation:AVIMConversation , unreadCount:Int = 0){
        let id = conversation.conversationId
        let data = NSKeyedArchiver.archivedDataWithRootObject(conversation.keyedConversation())
        let datastr = self.DB.escapeValue(data)
        let sql = "INSERT INTO \(conversationTableName) (\(F_ID),\(F_DATA),\(F_UNREAD_COUNT)) VALUES ('\(id)',\(datastr),\(unreadCount))"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \( SqliteError.errorMessageFromCode(ret))")
        }
    }
    
    func updateConversation(conversation:AVIMConversation){
        
        let id = conversation.conversationId
        let data = NSKeyedArchiver.archivedDataWithRootObject(conversation.keyedConversation())
        let datastr = self.DB.escapeValue(data)
        let sql = "UPDATE \(conversationTableName) SET \(F_DATA) = \(datastr) WHERE \(F_ID) = '\(id)'"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \( SqliteError.errorMessageFromCode(ret))")
        }
    }
    
    func deleteConversation(conversationID:String){
        let sql = "DELETE from \(conversationTableName) where \(F_ID) = '\(conversationID)'"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \(SqliteError.errorMessageFromCode(ret))")
        }else{
            self.deleteMessageTable(conversationID)
        }
    }
    
    func getConversation(conversationID:String)->AVIMConversation? {
        let sql = "SELECT * from \(conversationTableName) where \(F_ID) = '\(conversationID)' Limit 1"
        let (resultSet, err) = self.DB.executeQuery(sql)
        
        var conversation:AVIMConversation?
        if err == nil {
            for row in resultSet {
                if let data = row[F_DATA]?.asData(){
                    let keyedConversation = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! AVIMKeyedConversation
                    conversation = IMManager.instance.imClient!.conversationWithKeyedConversation(keyedConversation)
                    conversation?.unreadCount = row[F_UNREAD_COUNT]?.asInt() ?? 0
                }
            }
        } else {
            print("sqlite err : \( SqliteError.errorMessageFromCode(err!) )")
        }
        return conversation
    }
    
    func getAllConversation()->[AVIMConversation]{
        let sql = "SELECT * from \(conversationTableName) "
        let (resultSet, err) = self.DB.executeQuery(sql)
        
        var conversations = [AVIMConversation]()
        if err == nil {
            for row in resultSet {
                if let data = row[F_DATA]?.asData(){
                    let keyedConversation = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! AVIMKeyedConversation
                    let conversation = IMManager.instance.imClient!.conversationWithKeyedConversation(keyedConversation)
                    conversation?.unreadCount = row[F_UNREAD_COUNT]?.asInt() ?? 999
                    conversations.append(conversation)
                }
            }
        } else {
            print("sqlite err : \( SqliteError.errorMessageFromCode(err!) )")
        }
        return conversations
    }
    
    func increaseUnreadCount(conversationID:String){
        let id = conversationID
        let sql = "UPDATE \(conversationTableName) SET \(F_UNREAD_COUNT) = \(F_UNREAD_COUNT) + 1 WHERE \(F_ID) = '\(id)'"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \( SqliteError.errorMessageFromCode(ret))")
        }
    }
    func setUnreadCountToZero(conversationID:String){
        let id = conversationID
        let sql = "UPDATE \(conversationTableName) SET \(F_UNREAD_COUNT) = 0 WHERE \(F_ID) = '\(id)'"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \( SqliteError.errorMessageFromCode(ret))")
        }
    }
    
    //MARK: Message cache
    
    func messageTableName(conversationID:String)->String{
        return "msg_"+conversationID
    }
    func deleteMessageTable(conversationID:String)->Int?{
        return self.DB.deleteTable(self.messageTableName(conversationID))
    }
    
    func openMessageTable(conversationID:String)->Int?{
        return self.DB.createTable(self.messageTableName(conversationID), withColumnNamesAndTypes: [F_MESSAGE_ID :.StringVal , F_MESSAGE_DATA :.DataVal])
    }
    
    func appendMessage(conversationID:String,msg:AVIMTypedMessage){
        self.openMessageTable(conversationID)
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(msg)
        let datastr = self.DB.escapeValue(data)
        let sql = "INSERT INTO \(self.messageTableName(conversationID)) (\(F_MESSAGE_ID),\(F_MESSAGE_DATA)) VALUES ('\(msg.messageId)',\(datastr))"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \( SqliteError.errorMessageFromCode(ret))")
        }
    }
    
    func updateMessage(conversationID:String,msg:AVIMTypedMessage){
        let id = msg.messageId
        let data = NSKeyedArchiver.archivedDataWithRootObject(msg)
        let datastr = self.DB.escapeValue(data)
        let sql = "UPDATE \(self.messageTableName(conversationID)) SET \(F_MESSAGE_DATA) = \(datastr) WHERE \(F_MESSAGE_ID) = '\(id)'"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \( SqliteError.errorMessageFromCode(ret))")
        }
    }
    
    func removeMessage(conversationID:String,msgID:String){
        self.openMessageTable(conversationID)
        
        let sql = "DELETE from \(self.messageTableName(conversationID)) where \(F_MESSAGE_ID) = '\(msgID)'"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \(SqliteError.errorMessageFromCode(ret))")
        }
    }
    
    func getMessage(conversationID:String,msgID:String)->AVIMTypedMessage?{
        self.openMessageTable(conversationID)
        
        let sql = "SELECT * from \(self.messageTableName(conversationID)) where \(F_MESSAGE_ID) = '\(msgID)' Limit 1"
        let (resultSet, err) = self.DB.executeQuery(sql)
        
        var message:AVIMTypedMessage?
        if err == nil {
            for row in resultSet {
                if let data = row[F_MESSAGE_DATA]?.asData(){
                    message = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? AVIMTypedMessage
                    break
                }
            }
        } else {
            print("sqlite err : \( SqliteError.errorMessageFromCode(err!) )")
        }
        return message
    }
    
    func getMessages(conversationID:String,start:Int,limit:Int)->[AVIMTypedMessage]{
        self.openMessageTable(conversationID)
        
        var messages = [AVIMTypedMessage]()
        
        let countSql = "SELECT count(*) FROM \(self.messageTableName(conversationID))"
        let (countRow,errCode) = self.DB.executeQuery(countSql)
        if errCode != nil{
            print("sqlite err : \( SqliteError.errorMessageFromCode(errCode!) )")
            return messages
        }
        var count = countRow[0]["count(*)"]?.asInt() ?? 0
        var len = limit
        var offset = 0
        
        count -= start
        if (count - limit) >= 0 {
            offset = count - limit
        }else{
            offset = 0
            len = count
        }
        
        let sql = "SELECT * from \(self.messageTableName(conversationID)) Limit \(len) offset \(offset)"
        let (resultSet, err) = self.DB.executeQuery(sql)
        
        if err == nil {
            for row in resultSet {
                if let data = row[F_MESSAGE_DATA]?.asData(){
                    if let message = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? AVIMTypedMessage {
                        messages.append(message)
                    }
                }
            }
        } else {
            print("sqlite err : \( SqliteError.errorMessageFromCode(err!) )")
        }
        return messages
    }
}

