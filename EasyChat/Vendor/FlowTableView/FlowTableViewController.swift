//
//  FormViewController.swift
//  testTableView
//
//  Created by tanson on 15/12/29.
//  Copyright © 2015年 tanson. All rights reserved.
//

import UIKit

class FlowTableViewController: UIViewController{

    var flowDataDelegate:FlowDataDelegate?
    
    lazy var flowBuilder:FlowBuilder = {
        return FlowBuilder(controller: self)
    }()
    
    lazy var tableView: UITableView = {
        var view = UITableView(frame: CGRectZero, style: .Grouped)
        view.contentInset = UIEdgeInsetsZero
        view.scrollIndicatorInsets = UIEdgeInsetsZero
        return view
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.buildCells(flowBuilder)
        
        self.flowDataDelegate       = self.flowBuilder.buildDataDelegate()
        self.flowDataDelegate?.controller = self
        self.tableView.dataSource   = self.flowDataDelegate
        self.tableView.delegate     = self.flowDataDelegate
    }
    
    override func loadView() {
        self.view = self.tableView
    }
    
    func buildCells(builder: FlowBuilder) {
        fatalError("====== FormViewController : subclass must override buildCells()======")
    }
    
    func heightForHead(section: Int) -> CGFloat {
        return 10
    }


}
