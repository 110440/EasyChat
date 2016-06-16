//
//  Utility.swift
//  coder
//
//  Created by tanson on 16/6/7.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import UIKit

class Utility{
    
    class func createHorizontalLineView(w:CGFloat,h:CGFloat,color:UIColor)->UIView{
        let view = UIView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        view.backgroundColor = color
        return view
    }
}