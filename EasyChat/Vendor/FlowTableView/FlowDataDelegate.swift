//
//  FormDataDelegate.swift
//  testTableView
//
//  Created by tanson on 15/12/30.
//  Copyright © 2015 tanson. All rights reserved.
//

import UIKit

class FlowDataDelegate: NSObject ,UITableViewDataSource,UITableViewDelegate{

    var sections:[FlowDataSection]
    
    weak var controller:FlowTableViewController?
    
    init(sections:[FlowDataSection]) {
        self.sections = sections
        super.init()
    }
    
    // private
    private func cellForIndexPath(index:NSIndexPath)-> UITableViewCell{
        return self.sections[index.section].cellForRow(index.row)
    }
    
    //MARK:- UITableView Delegate -
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cellsCount
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.cellForIndexPath(indexPath)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return self.controller?.heightForHead(section) ?? 10
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if let cell = self.cellForIndexPath(indexPath) as? FlowBaseTableViewCell{
            return cell.hightForCell()
        }
        return 44.0
    }
    
    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//    }
//    
//    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//    }
    
}
