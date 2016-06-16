//
//  MessageViewController.swift
//  coder
//
//  Created by tanson on 16/6/11.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloudIM

class ConversationViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {

    var conversations = [AVIMConversation]()
    
    lazy var tableView:UITableView = {
        let view = UITableView(frame: self.view.bounds, style: UITableViewStyle.Plain)
        view.dataSource = self
        view.delegate = self
        view.registerNib(UINib(nibName: "ConversationCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.openChat), name:notifycationMsg_openChat, object: nil)
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "对话列表"
        self.view.addSubview(self.tableView)
    
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.updateList(_:)), name: IMNotifycationrFleshConversation, object: nil)
        
    }
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func openChat(){
        self.tabBarController?.selectedIndex = 0
        let vc = SendMessageViewController(nibName: "SendMessageViewController", bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true )
    }
    
    func updateList(n:NSNotification){
        self.conversations = IM.getAllRecentConversationFromCache()
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //
        self.conversations = IM.getAllRecentConversationFromCache()
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! ConversationCell
        let conversation = self.conversations[indexPath.row]
        cell.configCell(conversation)
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let conversation = self.conversations[indexPath.row]
        IMManager.instance.currentConversation = conversation
        let vc = SendMessageViewController(nibName: "SendMessageViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true )
    }
}
