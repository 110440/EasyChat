//
//  ConversationCell.swift
//  coder
//
//  Created by tanson on 16/6/15.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloudIM
import AVOSCloud
import Kingfisher


class ConversationCell: UITableViewCell {

    
    @IBOutlet weak var unreadCountLab: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var lastMsgLab: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.unreadCountLab.layer.cornerRadius = 3
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configCell(conversation:AVIMConversation){
        
        self.nameLab.text = conversation.conversationShowName
        self.lastMsgLab.text = conversation.lastMessage?.text
        self.unreadCountLab.text = String(conversation.unreadCount)
        if let friendID = conversation.friendID{
            AVUser.userCache.userByID(friendID, block: { (user, error) in
                if error == nil{
                    self.nameLab.text = user?.username
                    self.iconView.kf_setImageWithURL(NSURL(string: user!.avatar ?? "")!)
                }
            })
        }
    }
}
