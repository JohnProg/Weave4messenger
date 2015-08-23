//
//  Analytics.swift
//  msgur
//
//  Created by Roman on 21/05/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import Foundation
import Parse
import FBSDKCoreKit

class Analytics
{
    class func track(name: String, dimensions: [String: AnyObject?] = [:])
    {
        var dims: [String: String] = [:]
        for (dimStr, dimObj) in dimensions
        {
            if let obj: AnyObject = dimObj {
                dims[dimStr] = "\(obj)"
            }
        }
        println("TRACK \(name)=\(dims)")
//        PFAnalytics.trackEventInBackground(name, dimensions: dims, block: nil)
        FBSDKAppEvents.logEvent(name, parameters: dims)
    }
    
    class func trackAchievement(#desc: String)
    {
        println("TRACK ACHIEVEMENT \(desc)")
        FBSDKAppEvents.logEvent(FBSDKAppEventNameUnlockedAchievement, parameters: [FBSDKAppEventParameterNameDescription: desc])
    }
}
