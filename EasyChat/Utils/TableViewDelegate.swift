//
//  TableViewDelegate.swift
//  coder
//
//  Created by tanson on 16/6/14.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import UIKit

typealias TableViewCellConfigBlock = (tableView:UITableView,indexPath:NSIndexPath)->UITableViewCell
typealias CellDidSelectBlock = (tableView:UITableView,indexPath:NSIndexPath)->Void
typealias CellDidDeleteBlock = (tableView:UITableView,indexPath:NSIndexPath)->Void

class SingleSectionTableViewDelegate:NSObject,UITableViewDelegate,UITableViewDataSource{
    
    let cellCountBlock:()->Int
    let cellConfigBlock:TableViewCellConfigBlock
    var cellDidSelectBlock:CellDidSelectBlock?
    
    var cellDidDeleteBlock:CellDidDeleteBlock?{
        didSet{
            self.canEdit = true
        }
    }
    
    var canEdit = false
    
    init(cellCountBlock:()->Int,cellConfigBlock:TableViewCellConfigBlock){
        self.cellCountBlock = cellCountBlock
        self.cellConfigBlock = cellConfigBlock
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellCountBlock()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.cellConfigBlock(tableView: tableView, indexPath: indexPath)
    }
    
    //delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.cellDidSelectBlock?(tableView:tableView,indexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.canEdit
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.cellDidDeleteBlock?(tableView:tableView,indexPath:indexPath)
        }
    }
    
}