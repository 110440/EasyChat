//
//  SearchUserViewController.swift
//  EasyChat
//
//  Created by tanson on 16/6/16.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloud

class SearchUserViewController: UITableViewController ,UISearchBarDelegate{

    lazy var searchBar:UISearchBar = {
        let view = UISearchBar(frame: CGRect(x: 0, y: 0, width:self.view.bounds.width, height: 44))
        view.delegate = self
        view.placeholder = "输入用户名"
        return view
    }()
    
    var findUsers = [AVUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableHeaderView = self.searchBar

        self.title = "查找用户"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.findUsers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "cell")
        }
        let user = self.findUsers[indexPath.row]
        cell?.textLabel?.text = user.username ?? "无名字"
        cell?.detailTextLabel?.text = user.objectId
        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let vc = UserProfileViewController(style: .Grouped)
        vc.user = self.findUsers[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: search delegate
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        AVUser.currentUser().searchByUserName(searchBar.text!) { (users, error) in
            if error == nil{
                self.findUsers = users!
                self.tableView.reloadData()
            }else{
                print(error)
            }
        }
        
    }
}
