//
//  FormBuilder.swift
//  testTableView
//
//  Created by tanson on 15/12/29.
//  Copyright © 2015 tanson. All rights reserved.
//

import UIKit

class FlowBuilder: NSObject {

    var sections = [FlowDataSection]()
    
    weak var controller:FlowTableViewController?
    
    init(controller:FlowTableViewController) {
        self.controller = controller
        super.init()
    }
    
    func buildDataDelegate()->FlowDataDelegate {
        let delegate = FlowDataDelegate(sections: self.sections)
        return delegate
    }
    
    //MARK:- private 
    
    private var currentSection:FlowDataSection? {
        get {
            return self.sections.last
        }
    }
    
    private func addNewSection(s:FlowDataSection){
        self.sections.append(s)
    }
}


//MARK:- 重载 +=

func += (left:FlowBuilder , right:FlowDataSection){
    left.addNewSection(right)
}

func += (left:FlowBuilder , right:FlowBaseTableViewCell){
    
    if let curSection = left.currentSection{
        curSection.addNewCell(right)
        right.builder = left
        right.controller = left.controller
    }else{
        fatalError(" ======== must add a section at first ========== ")
    }
}
