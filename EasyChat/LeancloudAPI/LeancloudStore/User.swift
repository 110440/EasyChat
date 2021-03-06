//
//  UserManager.swift
//  coder
//
//  Created by tanson on 16/6/6.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloud

var userCache:UserCacheManager!

extension AVUser{
    
    class func signUpInBackground(userName:String,password:String,block:(user:AVUser?, error:NSError?)->Void){
        let  user       = AVUser()
        //user.email      = email
        user.username   = userName
        user.password   = password
        user.signUpInBackgroundWithBlock { (succeeded, error) in
            if succeeded{
                block(user: user, error: nil)
            }else{
                block(user: nil,error: error)
            }
        }
    }
    
    class func loginInBackground(user:String,password:String,block:(user:AVUser?, error:NSError?)->Void){
        AVUser.logInWithUsernameInBackground(user, password: password) { (user, error) in
            if user != nil{
                block(user: user, error: nil)
            }else{
                block(user: nil, error: error)
            }
        }
    }
    
    class func requestPasswordResetBackground(email:String,block:(error:NSError?)->Void){
        AVUser.requestPasswordResetForEmailInBackground(email) { (succeeded, error) in
            if succeeded{
                block(error: nil)
            }else{
                block(error: error)
            }
        }
    }
    
    //MARK: 好朋关系
    func getAllFriends(block:(friends:[AVUser]?,error:NSError?)->Void){
        self.getFollowers { (friends, error) in
            if error == nil{
                block(friends: friends as? [AVUser], error: nil)
            }else{
                block(friends: nil, error: error)
            }
        }
    }
    
    func setAllMakeFriendRequestReaded(block:(error:NSError?)->Void){
        let query = MakeFriendRequest.query()
        query.whereKey("toUser", equalTo: self.objectId)
        query.whereKey("readed", equalTo: NSNumber(bool: false))
        query.findObjectsInBackgroundWithBlock { (objs, error) in
            if error == nil{
                for request in objs as! [MakeFriendRequest] {
                    request.readed = NSNumber(bool: true)
                    request.saveInBackground()
                }
            }else{
                print(error)
            }
        }
    }
    
    func getMakeFriendRequests(block:(request:[MakeFriendRequest]?,error:NSError?)->Void){
        let query = MakeFriendRequest.query()
        query.whereKey("toUser", equalTo: self.objectId)
        query.includeKey("fromUser")
        query.findObjectsInBackgroundWithBlock { (objs, error) in
            if error == nil{
                block(request: objs as? [MakeFriendRequest] , error: nil)
            }else{
                block(request: nil, error: error)
            }
        }
    }
    
    // user :  user id
    func makeFriendWith(user:String,helloMsg:String,block:(error:NSError?)->Void){
        //往 makeFriendRequest 增加记录
        let sendMakeFriendRequest = {
            let request = MakeFriendRequest()
            request.fromUser = self
            request.toUser = user
            request.helloMsg = helloMsg
            request.readed = NSNumber(bool: false)
            request.state = NSNumber(integer: MakeFriendRequestState.Wait.rawValue)
            request.saveInBackgroundWithBlock { (succeeded, error) in
                if succeeded{
                    block(error: nil)
                }else{
                    block(error: error)
                }
            }
        }
        
        let query = MakeFriendRequest.query()
        query.whereKey("fromUser", equalTo: self)
        query.whereKey("toUser", equalTo: user)
        query.whereKey("state", equalTo: NSNumber(integer: MakeFriendRequestState.Wait.rawValue))
        query.countObjectsInBackgroundWithBlock { (count, error) in
            if error == nil{
                if count > 0 {
                    let error = NSError(domain: "己经请求过了", code: -1, userInfo: nil)
                    block(error: error)
                }else{
                    sendMakeFriendRequest()
                }
            }else{
                if error.code == kAVErrorObjectNotFound{
                    sendMakeFriendRequest()
                }else{
                    block(error: error)
                }
            }
        }
    }
    
    func agreeMakeFriendRequest(request:MakeFriendRequest,block:(error:NSError?)->Void){
        
        let followee = {
            self.follow(request.fromUser!.objectId, andCallback: { (succeeded, error) in
                if succeeded {
                    AVUser.userCache.updateUser(request.fromUser!)
                    block(error: nil)
                }else{
                    block(error: error)
                }
            })
        }
        
        request.state = NSNumber(integer: MakeFriendRequestState.Done.rawValue)
        request.saveInBackgroundWithBlock { (succeeded, error) in
            if succeeded{
                followee()
            }else{
                block(error: error)
            }
        }
    }
    
    func searchByUserName(name:String,block:(users:[AVUser]?,error:NSError?)->Void) {
        let q = AVUser.query()
        q.cachePolicy = .IgnoreCache
        q.whereKey("username", containsString: name )
        q.whereKey("objectId", notEqualTo: self.objectId)
        q.findObjectsInBackgroundWithBlock { (objs, error) in
            if error == nil {
                block(users: objs as? [AVUser], error: nil)
            }else{
                block(users: nil, error: error)
            }
        }
    }
    
    func updateFromNet(block:(user:AVUser?,error:NSError?)->Void){
        let q = AVUser.query()
        q.whereKey("objectId", equalTo: self.objectId)
        q.findObjectsInBackgroundWithBlock { (objs, error) in
            if error == nil{
                block(user: objs.first as? AVUser, error: nil)
            }else{
                block(user: nil, error: error)
            }
        }
    }
}

//MARK: - 自定义属性
private let avatarKey = "avatarKey"
extension AVUser{
    
    var avatar:String?{
        set{
            self.setObject(newValue, forKey: avatarKey)
        }
        get{
            return self.objectForKey(avatarKey) as? String
        }
    }
    
    static var userCache:UserCacheManager{
        return UserCacheManager(userID: AVUser.currentUser().objectId)
    }
}

//MARK:- ToDictionary

extension AVUser{

    // dictionary
    func toDictionary()->[String:AnyObject]{
        
        var dictionary = [String:AnyObject]()
        let allKey = self.allKeys()
        
        for key in allKey as! [String]{
            let value = self.objectForKey(key)
            dictionary[key] = value
        }
        dictionary["objectId"] = self.objectId
        dictionary["username"] = self.username
        return dictionary
    }
    
    convenience init(dictionary:Dictionary<String,AnyObject>) {
        self.init()
        self.objectId = dictionary["objectId"] as! String
        self.username = dictionary["username"] as? String
        
        for (key,value) in dictionary{
            if key != "objectId" && key != "username" {
                self.setObject(value, forKey: key)
            }
        }
    }
}






