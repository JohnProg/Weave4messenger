//
//  AdsRevmob.swift
//  msgur
//
//  Created by Roman on 12/05/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import Foundation
import Parse

class AdsHelper: NSObject {
    static let shared = AdsHelper()
    
    var interstitial: GADInterstitial?
    
    var interstitialCurrent = 1
    
    private override init() {
        super.init()
    }
    
    func amIallowedToShowAds() -> Bool {
        if UserDefaults.shared.videosSent < UserDefaults.shared.adsStartCount {
            println("AD I'm not allowed to show it yet")
            return false
        }
        return true
    }
    
    func preloadInterstitial() {
        if !amIallowedToShowAds() { return }
        if interstitialCurrent >= UserDefaults.shared.adsInterstitialsBetweenShows {
            println("AD preloading interstitial")
            interstitial = GADInterstitial(adUnitID: UserDefaults.shared.admobInterstitialId)
            let request = GADRequest()
            interstitial?.loadRequest(request)
        } else {
            println("AD skipping preloading")
        }
    }
    
    func showInterstitial(vc: UIViewController, doIfShowing: (()->())?) {
        if !amIallowedToShowAds() { return }
        if interstitialCurrent >= UserDefaults.shared.adsInterstitialsBetweenShows {
            if interstitial!.isReady {
                println("AD showing interstitial")
                doIfShowing?()
                interstitial?.presentFromRootViewController(vc)
                interstitialCurrent = 0
            } else {
                Analytics.track("ad_wasnt_ready")
                println("AD has to be shown, but wasn't ready")
            }
        } else {
            Analytics.track("ad_skipping_interstitial")
            println("AD skipping interstitial")
            interstitialCurrent++
        }
    }
    
}
