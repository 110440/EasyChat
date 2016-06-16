//
//  RootViewController.swift
//  coder
//
//  Created by tanson on 16/6/7.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloud

private let profileViewWidth:CGFloat = UIScreen.mainScreen().bounds.width * 2/3

class RootViewController: UITabBarController  {
    
    var contactsController:ContactsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "主页"
        
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.navigationBarTitleTextColor()]
        self.navigationController?.navigationBar.barTintColor = UIColor.navigationBarBackgroundColor()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.getMakeFriendRequest), name: IMNotifycationMakeFriendRequest, object: nil)
        
        self.setupViewController()
        self.connectToIM()
        self.getMakeFriendRequest()
    }

    func getMakeFriendRequest() {
        self.contactsController!.getMakeFriendRequest()
    }
    
    func connectToIM(){
        
        IMManager.instance.connectToSever(AVUser.currentUser().objectId) { (error) in
            if error == nil{
                print("连接 ＩＭ 服务器成功！")
            }else{
                print("连接 ＩＭ 服务器失败！@@@@@@@@@@@@@@@@@@@@@@@")
            }
        }
    }
    
    func setupViewController(){
        
        
        let conversationController = ConversationViewController()
        let conversation = self.configViewController(conversationController, title: "对话", image: "tabbar_mainframe", selectImg: "tabbar_mainframeHL")
        
        self.contactsController = ContactsViewController()
        let contacts = self.configViewController(self.contactsController!, title: "好友", image: "tabbar_contacts", selectImg: "tabbar_contactsHL")
        
        let profileController = ProfileViewController()
        let profile = self.configViewController(profileController, title: "我", image: "tabbar_me", selectImg: "tabbar_meHL")
        
        self.viewControllers = [conversation,contacts,profile]
    }
    
    private func configViewController(vc:UIViewController,title:String,image:String,selectImg:String)->UINavigationController{
        
        func getOriginalImage(name:String)->UIImage{
            let image = UIImage(named: name)
            return image!.imageWithRenderingMode(.AlwaysOriginal)
        }
        vc.tabBarItem.title = title
        vc.tabBarItem.image = getOriginalImage(image)
        vc.tabBarItem.selectedImage = getOriginalImage(selectImg)
        vc.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGrayColor()], forState: .Normal)
        vc.tabBarItem!.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.hexStr("#68BB1E", alpha: 1)], forState: .Selected)
        return UINavigationController(rootViewController: vc)
    }
    
}
