//
//  ProfileViewController.swift
//  EasyChat
//
//  Created by tanson on 16/6/15.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloud

private let settings = ["资料","什么","又什么"]

class MeViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "我"
        self.tableView.registerNib(UINib(nibName: "UserIconCell", bundle: nil), forCellReuseIdentifier: "icon")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 1
        }
        return settings.count
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
            let user = AVUser.currentUser()
            cell = tableView.dequeueReusableCellWithIdentifier("icon")
            (cell as! UserIconCell).nameLab.text = user?.username
            (cell as! UserIconCell).idLab.text = user?.objectId
        }else{
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
            cell?.textLabel?.text = settings[indexPath.row]
            cell?.accessoryType = .DisclosureIndicator
        }
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 {
            
        }
    }

}
