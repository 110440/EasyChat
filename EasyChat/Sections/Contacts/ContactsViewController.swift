//
//  ContactsViewController.swift
//  EasyChat
//
//  Created by tanson on 16/6/15.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloud

class ContactsViewController: UITableViewController {

    var friends = [AVUser]()
    var makeFriendRequests = [MakeFriendRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "好友列表"
        let addBtn = UIBarButtonItem(title: "增加好友", style: .Plain, target: self, action: #selector(self.addFriend))
        self.navigationItem.rightBarButtonItem = addBtn
        
        // register
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "friendCell")
        self.tableView.registerNib(UINib(nibName:"MakefriendRequestCell",bundle:nil), forCellReuseIdentifier: "requestCell")
        self.getFriends()
        self.getMakeFriendRequest()
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func getFriends(){
        guard let user = AVUser.currentUser() else { return }
        user.getAllFriends { (friends, error) in
            if error == nil{
                self.friends = friends!
                self.tableView.reloadData()
            }else{
                print(error)
            }
        }
    }
    
    func addFriend(){
//        let vc = AddNewFriendViewController(nibName: "AddNewFriendViewController", bundle: nil)
        let vc = SearchUserViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true )
    }

    //
    func getMakeFriendRequest(){
        guard let user = AVUser.currentUser() else { return }
        user.getMakeFriendRequests({ (request, error) in
            if error == nil{
                
                self.makeFriendRequests = request!
                self.tableView.reloadData()
                
                let unreadCount = request!.filter{ $0.readed == false }.count
                if unreadCount > 0 {
                    self.tabBarItem.badgeValue = String(unreadCount)
                    user.setAllMakeFriendRequestReaded({ (error) in
                        if error != nil{
                            print(error)
                        }
                    })
                }else{
                    self.tabBarItem.badgeValue = nil
                }
            }else{
                print(error)
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return self.makeFriendRequests.count
        }else{
            return self.friends.count
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell:UITableViewCell!
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("requestCell", forIndexPath: indexPath)
            let request = self.makeFriendRequests[indexPath.row]
            cell.textLabel?.text = request.fromUser?.username
            cell.detailTextLabel?.text = request.helloMsg
            
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier("friendCell", forIndexPath: indexPath)
            cell.textLabel?.text = self.friends[indexPath.row].username
            cell.imageView?.image = UIImage(named: "plugins_FriendNotify")
        }

        return cell
    }
 
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0{
            //print("＝＝＝＝＝已同意请求＝＝＝＝")
            let request = self.makeFriendRequests[indexPath.row]
            if request.state == MakeFriendRequestState.Done.rawValue {
                return
            }
            if let user = AVUser.currentUser(){
                user.agreeMakeFriendRequest(request, block: { (error) in
                    if error == nil{
                        print("加好友成功")
                        self.getFriends()
                        IM.createSingleConversation(request.fromUser!.objectId!, name: "", block: { (conversation, error) in
                            if error == nil{
                                IM.currentConversation = conversation
                                NSNotificationCenter.defaultCenter().postNotificationName(notifycationMsg_openChat, object: nil)
                            }else{
                                print(error)
                            }
                        })
                        AVUser.currentUser().setAllMakeFriendRequestReaded({ (error) in
                            
                        })
                    }else{
                        print(error)
                    }
                })
            }
            
        }else {
            
            let user = self.friends[indexPath.row]
            IM.createSingleConversation(user.objectId!, name:"", block: { (conversation, error) in
                if let con = conversation{
                    IM.currentConversation = con
                    IM.setCurConversationUnreadCountToZero()
                    print("创建会话成功！")
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(notifycationMsg_openChat, object: nil)
                    //let chatVC = SendMessageViewController(nibName: "SendMessageViewController", bundle: nil)
                    //self.navigationController?.pushViewController(chatVC, animated: true)
                    
                }else{
                    print(error)
                }
            })
            
        }
    }
    
    override  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        return 50
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
