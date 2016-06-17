//
//  ChatViewController.swift
//  EasyChat
//
//  Created by tanson on 16/6/17.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloud
import AVOSCloudIM
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var incomingBubble: JSQMessagesBubbleImage?
    var outgoingBubble: JSQMessagesBubbleImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        // Override point:
        //
        // Here is an exaple of how you can cusomize the bubble appearence for incoming and outgoing messages.
        // Based on the Settigns of the user we will display two differnent type of bubbles.
        
        incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.lightGrayColor())
        
        // This is how you remove Avatars from the messagesView
        collectionView?.collectionViewLayout.incomingAvatarViewSize = .zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        
        // This is a beta feature that mostly works but to make things more stable I have diabled it.
        collectionView?.collectionViewLayout.springinessEnabled = false
        
        //Set the SenderId  to the current User
        // For this Demo we will use Woz's ID
        // Anywhere that AvatarIDWoz is used you should replace with you currentUserVariable
        senderId = AVUser.currentUser().objectId
        senderDisplayName = AVUser.currentUser().username
        automaticallyScrollsToMostRecentMessage = true
        
        //Get Messages
        //TOTO: clientID == nil ??? why
        let msgs = IM.getCurConversationMessages(0, limit: 10)
        for msg in msgs{
            var message:JSQMessage?
            let clientID = msg.clientId ?? AVUser.currentUser().objectId!
            if let user = AVUser.userCache.userByID(clientID) {
                message = JSQMessage(senderId: clientID, displayName: user.username, text: msg.text)
            }else{
                message = JSQMessage(senderId: clientID, displayName: "未知", text: msg.text)
            }
            self.messages.append(message!)
        }
        self.collectionView?.reloadData()
        self.collectionView?.layoutIfNeeded()
        
        //清空未读消息数
        self.title = IM.currentConversation?.name
        IM.setCurConversationUnreadCountToZero()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.recveNewMsg(_:)), name: IMNotifycationRecvNewMessage, object: nil)
    }

    func recveNewMsg(n:NSNotification){
        let message = n.object as! AVIMTypedMessage
        if message.conversationId == IM.currentConversation?.conversationId{
            
            var jsqMessage:JSQMessage?
            if let user = AVUser.userCache.userByID(message.clientId) {
                jsqMessage = JSQMessage(senderId: message.clientId, displayName: user.username, text: message.text)
            }else{
                jsqMessage = JSQMessage(senderId: message.clientId, displayName: "未知", text: message.text)
            }
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            self.messages.append(jsqMessage!)
            self.finishReceivingMessageAnimated(true)
        }
    }
    
    deinit{
        IM.currentConversation = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: JSQMessagesViewController method overrides
    override func didPressSendButton(button: UIButton?, withMessageText text: String?, senderId: String?, senderDisplayName: String?, date: NSDate?) {
        /**
         *  Sending a message. Your implementation of this method should do *at least* the following:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishSendingMessage`
         */
        
        
        
        //TODO: realy to send msg 
        
        if text?.characters.count > 0 {
            let msg = AVIMTextMessage(text: text!, attributes: nil)
            IM.sendMessageToCurrentConversation(msg, block: { (error) in
                if error == nil{
                    print("发送消息成功！")
                }else{
                    print(error)
                }
            })
        }
        
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        self.messages.append(message)
        self.finishSendingMessageAnimated(true)
    }
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView?, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData? {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView?, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource? {
        return messages[indexPath.item].senderId == AVUser.currentUser().objectId ? outgoingBubble : incomingBubble
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource? {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView?, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        switch message.senderId {
        //Here we are displaying everyones name above their message except for the "Senders"
        case AVUser.currentUser().objectId:
            return nil
        default:
            guard let senderDisplayName = message.senderDisplayName else {
                assertionFailure()
                return nil
            }
            return NSAttributedString(string: senderDisplayName)
            
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView?, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout?, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return messages[indexPath.item].senderId == AVUser.currentUser().objectId ? 0 : kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        self.inputToolbar.contentView.textView.resignFirstResponder()
    }
}