//
//  InputUserToChatViewController.swift
//  coder
//
//  Created by tanson on 16/6/11.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloud

class AddNewFriendViewController: UIViewController {

    @IBOutlet weak var inputUserFeild: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    //加好友
    @IBAction func startChat(sender: AnyObject) {
        
        let userID = self.inputUserFeild.text
        if userID?.characters.count > 0 {
            AVUser.currentUser().makeFriendWith(userID!, helloMsg: "你好", block: { (error) in
                if error == nil {
                    IM.sendMakeFriendRequest(userID!, block: { (error) in
                        if error == nil{
                            let al = UIAlertView(title: nil, message: "发送请求成功", delegate: nil, cancelButtonTitle: "确定")
                            al.show()
                        }else{
                            print(error)
                        }
                    })
                }else{
                    print(error)
                }
            })
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
