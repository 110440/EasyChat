//
//  SendMessageViewController.swift
//  coder
//
//  Created by tanson on 16/6/11.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloudIM

class SendMessageViewController: UIViewController , UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputMessageFeild: UITextField!
    
    lazy var refleshCtl:UIRefreshControl = {
        let c = UIRefreshControl()
        c.addTarget(self, action: #selector(self.flesh(_:)), forControlEvents: .ValueChanged)
        return c
    }()
    
    func flesh(sender:UIRefreshControl){
        let start = self.messages.count

        let newMsges = IM.getCurConversationMessages(start, limit: 10)
        self.messages = newMsges + self.messages
        self.tableView.reloadData()
        sender.endRefreshing()
    }
    
    var messages = [AVIMTypedMessage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = IM.currentConversation?.name
        
        let messages = IM.getCurConversationMessages(0, limit: 10)
        self.messages = messages
        self.tableView.reloadData()
        self.tableView.addSubview(self.refleshCtl)
        
        //清空未读消息数
        IM.setCurConversationUnreadCountToZero()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.recveNewMsg(_:)), name: IMNotifycationRecvNewMessage, object: nil)
    }
    
    func recveNewMsg(n:NSNotification){
        let message = n.object as! AVIMTypedMessage
        if message.conversationId == IM.currentConversation?.conversationId{
            self.messages.append(message)
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    deinit{
        IM.currentConversation = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func send(sender: AnyObject) {
        let messageStr = self.inputMessageFeild.text
        if messageStr?.characters.count > 0 {
            let msg = AVIMTextMessage(text: messageStr!, attributes: nil)
            IMManager.instance.sendMessageToCurrentConversation(msg, block: { (error) in
                if error == nil{
                    print("发送消息成功！")
                }else{
                    print(error)
                }
            })
            self.view.endEditing(true)
            self.messages.append(msg)
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }

    func scrollToBottom(){
        let rows = self.tableView.numberOfRowsInSection(0)
        if rows > 0 {
            let indexPath = NSIndexPath(forRow: rows-1, inSection: 0)
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    //
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
        let message = self.messages[indexPath.row]
        cell.textLabel?.text = message.text
        if message.ioType == AVIMMessageIOTypeOut {
            cell.textLabel?.textAlignment = .Right
            cell.textLabel?.textColor = UIColor.redColor()
        }
        
        return cell
    }
    
}
