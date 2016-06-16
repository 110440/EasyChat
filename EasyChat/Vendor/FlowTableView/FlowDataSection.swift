//
//  FormSection.swift
//  testTableView
//
//  Created by tanson on 15/12/29.
//  Copyright © 2015年 tanson. All rights reserved.
//

import UIKit

class FlowDataSection: NSObject {

    var cells = [FlowBaseTableViewCell]()
    
    var cellsCount:Int{
        return self.cells.count
    }
    
    override init() {
        super.init()
    }
    
    func addNewCell(cell:FlowBaseTableViewCell){
        self.cells.append(cell)
    }
    
    func cellForRow(row:Int)->FlowBaseTableViewCell
    {
        return self.cells[row]
    }

}
