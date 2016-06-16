//
//  ConversationCell.swift
//  coder
//
//  Created by tanson on 16/6/15.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloudIM

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
    }
}
