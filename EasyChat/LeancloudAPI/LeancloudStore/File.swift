//
//  File.swift
//  coder
//
//  Created by tanson on 16/6/6.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import AVOSCloud

extension AVFile{
    
    class func uploadImages(images:[UIImage],block:(fileUrls:[String]?,error:NSError?)->Void){
        
        let dispatchGroup = dispatch_group_create()
        let queue = dispatch_get_global_queue(0, 0)
        var fileUrls = [String]()
        
        for image in images{
            let file = AVFile(data: UIImagePNGRepresentation(image))
            dispatch_group_async(dispatchGroup, queue, { 
                if file.save() {
                    fileUrls.append(file.url)
                }
            })
        }
        let mainQueue = dispatch_get_main_queue()
        dispatch_group_notify(dispatchGroup, mainQueue) { 
            if fileUrls.count < images.count{
                let error = NSError(domain: "上传错误", code: -1, userInfo: nil)
                block(fileUrls: nil, error: error)
            }else{
                block(fileUrls: fileUrls, error: nil)
            }
        }
    }
}