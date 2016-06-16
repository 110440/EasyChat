//
//  NSTimer+block.swift
//  coder
//
//  Created by tanson on 16/6/8.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation


public typealias TT_circle_TimerHandler = (timer: NSTimer) -> Void
extension NSTimer {
    
    class public func tt_circle_scheduledTimerWithTimeInterval(interval: NSTimeInterval, repeats: Bool = false,
                                                               handler: TT_circle_TimerHandler) -> NSTimer
    {
        return NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(NSTimer.invokeFromTimer(_:)),
                                                      userInfo: TimerClosureWrapper(handler: handler, repeats: repeats), repeats: repeats)
    }
    
    // MARK: Private methods
    
    @objc
    class private func invokeFromTimer(timer: NSTimer) {
        if let closureWrapper = timer.userInfo as? TimerClosureWrapper {
            closureWrapper.handler(timer: timer)
        }
    }
}

// MARK: - Private classes

private final class TimerClosureWrapper {
    private var handler: TT_circle_TimerHandler
    private var repeats: Bool
    
    init(handler: TT_circle_TimerHandler, repeats: Bool) {
        self.handler = handler
        self.repeats = repeats
    }
}