//
//  UserCacheManager.swift
//  EasyChat
//
//  Created by tanson on 16/6/16.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloud

private func getDBName(userID:String)->String{
    return "user_" + userID
}

private let tableName = "table_user"
private let f_userID = "user_id"
private let f_userData = "user_data"

class  UserCacheManager: NSObject {
    
    var DB:SqliteDB
    init(userID:String) {
        self.DB = SqliteDB(name: getDBName(userID) )
        self.DB.createTable(tableName, withColumnNamesAndTypes: [f_userID:.StringVal , f_userData:.DataVal])
    }
    
    func isUserExit(userId:String)->Bool{
        let sql = "SELECT * from \(tableName) where \(f_userID) = '\(userId)' Limit 1"
        let (resultSet, err) = self.DB.executeQuery(sql)
        if err == nil {
            if resultSet.count > 0 { return true }
        } else {
            print("sqlite err : \( SqliteError.errorMessageFromCode(err!) )")
        }
        return false
    }
    
    func insertUser(user:AVUser){
        let id = user.objectId
        let data = NSKeyedArchiver.archivedDataWithRootObject(user.toDictionary())
        let datastr = self.DB.escapeValue(data)
        let sql = "INSERT INTO \(tableName) (\(f_userID),\(f_userData)) VALUES ('\(id)',\(datastr))"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \( SqliteError.errorMessageFromCode(ret))")
        }
    }
    
    func updateUser(user:AVUser){
        if !self.isUserExit(user.objectId){
            self.insertUser(user)
        }else{
            let id = user.objectId
            let data = NSKeyedArchiver.archivedDataWithRootObject(user.toDictionary())
            let datastr = self.DB.escapeValue(data)
            let sql = "UPDATE  \(tableName) SET \(f_userData) = \(datastr) where \(f_userID) = '\(id)'"
            if let ret = self.DB.executeChange(sql){
                print("sqlite err : \( SqliteError.errorMessageFromCode(ret))")
            }
        }
    }
    
    func updateUsers(users:[AVUser]){
        for user in users{
            self.updateUser(user)
        }
    }
    
    func userByID(userID:String)->AVUser?{
        
        let sql = "SELECT * from \(tableName) where \(f_userID) = '\(userID)' Limit 1"
        let (resultSet, err) = self.DB.executeQuery(sql)
        
        var user:AVUser?
        if err == nil {
            for row in resultSet {
                if let data = row[f_userData]?.asData(){
                    let dictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String:AnyObject]
                    user = AVUser(dictionary: dictionary)
                }
            }
        } else {
            print("sqlite err : \( SqliteError.errorMessageFromCode(err!) )")
        }
        return user
    }
    
    func userByID(userID:String,block:(user:AVUser?,error:NSError?)->Void){
        
        let user = self.userByID(userID)
        if user == nil {
            let user = AVUser(objectId: userID)
            user.updateFromNet({ (user, error) in
                if error == nil{
                    self.insertUser(user!)
                    block(user: user, error:nil)
                }else{
                    block(user: nil, error: error)
                }
            })
        }else{
            block(user: user, error: nil)
        }
    }
    
    func getAllUserFromCacheIgnoreSelf()->[AVUser]{
        
        let curUser = AVUser.currentUser()
        let sql = "SELECT * from \(tableName) where \(f_userID) != '\(curUser.objectId)'"
        let (resultSet, err) = self.DB.executeQuery(sql)
        
        var users = [AVUser]()
        if err == nil {
            for row in resultSet {
                if let data = row[f_userData]?.asData(){
                    let dictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String:AnyObject]
                    let user = AVUser(dictionary: dictionary)
                    users.append(user)
                }
            }
        } else {
            print("sqlite err : \( SqliteError.errorMessageFromCode(err!) )")
        }
        return users
    }
    
    func deleteUser(userID:String){
        let sql = "DELETE from \(tableName) where \(f_userID) = '\(userID)'"
        if let ret = self.DB.executeChange(sql){
            print("sqlite err : \(SqliteError.errorMessageFromCode(ret))")
        }
    }
}


