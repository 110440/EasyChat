//
//  ProfileViewController.swift
//  EasyChat
//
//  Created by tanson on 16/6/15.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloud
import Kingfisher

private let settings = ["资料","什么","又什么"]

class MeViewController: UITableViewController {

    var photoHelper:MCPhotographyHelper = {
        let helper = MCPhotographyHelper()
        return helper
    }()
    
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
            (cell as! UserIconCell).iconVIew.kf_setImageWithURL(NSURL(string: user.avatar ?? "")!)
        }else{
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
            cell?.textLabel?.text = settings[indexPath.row]
            cell?.accessoryType = .DisclosureIndicator
        }
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            self.photoHelper.showOnPickerViewControllerOnViewController(self, completion: { (image) in
                if let selectImg = image{
                    let newImage = selectImg.imageByResizeToSize(CGSize(width: 50, height: 50))
                    let data = UIImagePNGRepresentation(newImage!)
                    let file = AVFile(data: data)
                    print("上传图片...")
                    file.saveInBackgroundWithBlock({ (ok, error) in
                        if ok{
                            AVUser.currentUser().avatar = file.url
                            AVUser.currentUser().saveInBackgroundWithBlock({ (ok, error) in
                                if ok {
                                    let al = UIAlertView(title: nil, message: "更换头像成功", delegate: nil, cancelButtonTitle: "OK")
                                    al.show()
                                    self.tableView.reloadData()
                                }else{
                                    print(error)
                                }
                            })
                        }
                    })
                }
            })
        }
    }

}
