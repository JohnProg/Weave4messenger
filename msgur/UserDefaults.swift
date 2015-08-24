//
//  UserDefaults.swift
//  msgur
//
//  Created by Roman on 08/05/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import UIKit
import Parse

class UserDefaults {
    static let shared = UserDefaults()
    
    private lazy var userDefs = NSUserDefaults.standardUserDefaults()
    private let deviceModelName = UIDevice.currentDevice().modelName
    private lazy var config = PFConfig.currentConfig()
    
    private init() {
        Parse.setApplicationId(parseAppId, clientKey: parseClientKey)
    }
    
    private var refreshRemoteConfigMade = false
    func refreshRemoteConfig() {
        if refreshRemoteConfigMade { return }
        println("CONFIG refresh")
        PFConfig.getConfigInBackgroundWithBlock { (_, error) -> Void in
            if error == nil {
                println("CONFIG fetched")
                self.refreshRemoteConfigMade = true
                self.config = PFConfig.currentConfig()
            } else {
                Analytics.track("err_configFetch")
            }
        }
    }
    
    var isSlowDevice: Bool {
        get {
            return deviceModelName == "iPhone4,1" || deviceModelName == "iPod5,1"
        }
    }
    
    private var instances: [String: Int] = [:]
    
    func countInits(id: String) {
        if let instance = instances[id] {
            instances[id]!++
        } else {
            instances[id] = 1
        }
        println("-*- \(id) INIT, \(instances[id]!) TOTAL")
    }

    func countDeinits(id: String) {
        instances[id]!--
        println("-*- \(id) DEINIT, \(instances[id]!) LEFT")
    }
    // MARK: - CONSTANT CONFIG
    
    let colorPalette = [
        UIColor(red:0.933, green:0.416, blue:0.427, alpha: 1),
        UIColor(red:0.941, green:0.882, blue:0.400, alpha: 1),
        UIColor(red:0.451, green:0.980, blue:0.439, alpha: 1),
        UIColor(red:0.478, green:0.965, blue:0.910, alpha: 1),
        UIColor(red:0.467, green:0.522, blue:0.969, alpha: 1),
        UIColor(red:0.737, green:0.361, blue:0.969, alpha: 1)
    ]
    private let parseAppId = ""
    private let parseClientKey = ""
    let appStoreID = "994829540"
    let admobInterstitialId = ""
    
    // MARK: - REMOTE CONFIG WITH DEFAULTS
    
    var learnMorePageUrl: String {
        get {
            return config[__FUNCTION__] as? String ?? "http://facebook.com/weave4messenger"
        }
    }
    var inviteUrl: String {
        get {
            return config[__FUNCTION__] as? String ?? "https://fb.me/1625093717704137"
        }
    }
//    var xxx: Int {
//        get {
//            return config[__FUNCTION__] as? Int ?? yyy
//        }
//    }
    var fbOverrideContextTimeout: Double {
        get {
            return (config[__FUNCTION__] as? NSNumber)?.doubleValue ?? 900.0
        }
    }
    var armchairSendsUntilPrompt: UInt {
        get {
            return config[__FUNCTION__] as? UInt ?? 7
        }
    }
    var armchairDaysUntilPrompt: UInt {
        get {
            return config[__FUNCTION__] as? UInt ?? 0
        }
    }
    var armchairUsesUntilPrompt: UInt {
        get {
            return config[__FUNCTION__] as? UInt ?? 0
        }
    }
    var adsStartCount: Int {
        get {
            return config[__FUNCTION__] as? Int ?? 12
        }
    }
    var adsInterstitialShowAfterPlayerRepeat: Int {
        get {
            return config[__FUNCTION__] as? Int ?? 2
        }
    }
    var adsInterstitialsBetweenShows: Int {
        get {
            return config[__FUNCTION__] as? Int ?? 1
        }
    }
    
    // MARK: - USERDEFAULTS LOCALLY STORED VARIABLES
    
    private let lastColorKey = "lastColor"
    private let videosSentKey = "videosSent"
    
    var lastColor: UIColor {
        get {
            let index = userDefs.integerForKey(lastColorKey)        // 0 if not exists
            if index >= colorPalette.startIndex && index <= colorPalette.endIndex {
                return colorPalette[index]
            } else {
                return colorPalette[0]
            }
        }
        set {
            if let i = find(colorPalette, newValue) {
                userDefs.setInteger(i, forKey: lastColorKey)
            }
        }
    }

//    var xxx: Int {
//        get {
//            return userDefs.integerForKey(xxxKey)
//        }
//        set {
//            userDefs.setInteger(newValue, forKey: xxxKey)
//        }
//    }
    
    var videosSent: Int {
        get {
            return userDefs.integerForKey(videosSentKey)
        }
        set {
            userDefs.setInteger(newValue, forKey: videosSentKey)
            println("\(__FUNCTION__)=\(newValue)")
        }
    }
    
    
}


