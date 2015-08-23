//
//  Extensions.swift
//  msgur
//
//  Created by asdfgh1 on 17/05/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import Foundation
import Parse

extension NSTimer {
    class func scheduledTimerWithTimeInterval(interval: NSTimeInterval, repeats: Bool, handler: (NSTimer!)->(Void)) -> NSTimer {
        let fireDate = interval + CFAbsoluteTimeGetCurrent()
        let repeatInterval = repeats ? interval : 0
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, repeatInterval, 0, 0, handler)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes)
        return timer
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        let mirror = reflect(machine)
        var identifier = ""
        
        for i in 0..<mirror.count {
            if let value = mirror[i].1.value as? Int8 where value != 0 {
                identifier.append(UnicodeScalar(UInt8(value)))
            }
        }
        return identifier
    }
}

extension UIScreen
{
    func isSmallScreen() -> Bool
    {
        return self.bounds.height <= 480
    }
    
}
