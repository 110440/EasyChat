//
//  UserIconCell.swift
//  EasyChat
//
//  Created by tanson on 16/6/16.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

class UserIconCell: UITableViewCell {

    @IBOutlet weak var idLab: UILabel!
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var iconVIew: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    
}
