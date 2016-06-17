//
//  Image.swift
//  EasyChat
//
//  Created by tanson on 16/6/17.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import UIKit

extension UIImage{
    
    func imageByResizeToSize(size:CGSize)->UIImage?{
        if (size.width <= 0 || size.height <= 0) {return nil}
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        self.drawInRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}