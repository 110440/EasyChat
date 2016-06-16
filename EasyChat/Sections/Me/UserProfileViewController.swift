//
//  UserProfileViewController.swift
//  EasyChat
//
//  Created by tanson on 16/6/16.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloud

class UserProfileViewController: UITableViewController {

    var user:AVUser?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.user?.username
        self.tableView.registerNib(UINib(nibName: "UserIconCell", bundle: nil), forCellReuseIdentifier: "icon")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        if indexPath.section == 0 {
            return 70
        }else{
            return 44
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell?
        if indexPath.section == 0{
            cell = tableView.dequeueReusableCellWithIdentifier("icon")
            (cell as! UserIconCell).nameLab.text = self.user?.username
            (cell as! UserIconCell).idLab.text = self.user?.objectId
        }else{
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
            cell?.textLabel?.text = "加好友"
            cell?.accessoryType = .DisclosureIndicator
        }
        return cell!
    }
 
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1{
            
            let user = self.user!
            
            AVUser.currentUser().makeFriendWith(user.objectId, helloMsg: "你好", block: { (error) in
                if error == nil {
                    IM.sendMakeFriendRequest(user.objectId, block: { (error) in
                        if error == nil{
                            let al = UIAlertView(title: nil, message: "发送请求成功", delegate: nil, cancelButtonTitle: "确定")
                            al.show()
                        }else{
                            print(error)
                        }
                    })
                }else{
                    print(error)
                }
            })
        }
    }
}
