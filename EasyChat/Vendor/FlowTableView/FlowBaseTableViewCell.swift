//
//  FlowBaseTableViewCell.swift
//  coder
//
//  Created by tanson on 16/6/8.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

class FlowBaseTableViewCell: UITableViewCell {

    var builder:FlowBuilder?
    var controller:FlowTableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func hightForCell()->CGFloat{
        return 100
    }
}

extension FlowBaseTableViewCell {
    
    class func fromNib<T : FlowBaseTableViewCell>(nibNameOrNil: String? = nil) -> T {
        var view: T?
        let name: String
        if let nibName = nibNameOrNil {
            name = nibName
        } else {
            name = "\(T.self)".componentsSeparatedByString(".").last!
        }
        let nibViews = NSBundle.mainBundle().loadNibNamed(name, owner: nil, options: nil)
        for v in nibViews {
            if let tog = v as? T {
                view = tog
            }
        }
        return view!
    }
}
