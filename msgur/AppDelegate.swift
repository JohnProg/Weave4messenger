//
//  AppDelegate.swift
//  msgur
//
//  Created by asdfgh1 on 18/04/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import UIKit
import Armchair
import FBSDKCoreKit
import FBSDKMessengerShareKit
import Parse

var lastMsgrContext: NSTimeInterval?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FBSDKMessengerURLHandlerDelegate {

    var window: UIWindow?
    let messengerUrlHandler = FBSDKMessengerURLHandler()

    override class func initialize() {
        UserDefaults.shared
        Armchair.appID(UserDefaults.shared.appStoreID)
        Armchair.significantEventsUntilPrompt(UserDefaults.shared.armchairSendsUntilPrompt)
        Armchair.daysUntilPrompt(UserDefaults.shared.armchairDaysUntilPrompt)
        Armchair.usesUntilPrompt(UserDefaults.shared.armchairUsesUntilPrompt)
        Armchair.opensInStoreKit(false)
//        Armchair.debugEnabled(true)
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
        messengerUrlHandler.delegate = self
        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {

        if messengerUrlHandler.canOpenURL(url, sourceApplication: sourceApplication) {
            println("handling via MsgrUrlHandler")
            messengerUrlHandler.openURL(url, sourceApplication: sourceApplication)
        }
        
        return true
    }
    
    func messengerURLHandler(messengerURLHandler: FBSDKMessengerURLHandler!, didHandleOpenFromComposerWithContext context: FBSDKMessengerURLHandlerOpenFromComposerContext!) {
        println("got compose")
        lastMsgrContext = NSDate.timeIntervalSinceReferenceDate()
//        println(context.metadata)
        NSNotificationCenter.defaultCenter().postNotificationName("messengerURLHandler", object: nil)
        Analytics.track("msgrCompose")
    }
    
    func messengerURLHandler(messengerURLHandler: FBSDKMessengerURLHandler!, didHandleReplyWithContext context: FBSDKMessengerURLHandlerReplyContext!) {
        println("got reply")
        lastMsgrContext = NSDate.timeIntervalSinceReferenceDate()
//        println(context.metadata)
        NSNotificationCenter.defaultCenter().postNotificationName("messengerURLHandler", object: nil)
        Analytics.track("msgrReply")
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

