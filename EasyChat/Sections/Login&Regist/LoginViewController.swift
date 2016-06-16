//
//  LoginViewController.swift
//  coder
//
//  Created by tanson on 16/6/11.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import AVOSCloud

class LoginViewController: UIViewController {

    @IBOutlet weak var userNameFeild: UITextField!
    @IBOutlet weak var passwordFeild: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender: AnyObject) {
        
        let userName = self.userNameFeild.text
        let password = self.passwordFeild.text
        
        if userName?.characters.count > 0 && password?.characters.count > 0{
            AVUser.loginInBackground(userName!, password: password!, block: { (user, error) in
                if error == nil{
                    IMManager.instance.connectToSever(AVUser.currentUser().objectId) { (error) in
                        if error == nil{
                            print("连接 ＩＭ 服务器成功！")
                            (UIApplication.sharedApplication().delegate as! AppDelegate).toMainView()
                        }else{
                            print("连接 ＩＭ 服务器失败！")
                        }
                    }
                }
            })
        }
    }

    @IBAction func singin(sender: AnyObject) {
        let userName = self.userNameFeild.text
        let password = self.passwordFeild.text
        
        if userName?.characters.count > 0 && password?.characters.count > 0{
            AVUser.signUpInBackground(userName!, password: password!, block: { (user, error) in
                if error == nil{
                    
                    IMManager.instance.connectToSever(AVUser.currentUser().objectId) { (error) in
                        if error == nil{
                            print("连接 ＩＭ 服务器成功！")
                            (UIApplication.sharedApplication().delegate as! AppDelegate).toMainView()
                        }else{
                            print("连接 ＩＭ 服务器失败！")
                        }
                    }
                }
            })
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

}
