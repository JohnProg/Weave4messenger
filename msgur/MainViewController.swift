//
//  MainViewController.swift
//  msgur
//
//  Created by asdfgh1 on 18/04/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import UIKit
import Armchair
import FBSDKCoreKit
import FBSDKMessengerShareKit
import FBSDKShareKit
import Parse

class MainViewController: UIViewController, CanvasViewDelegate, ColorSelectControllerDelegate, PlayerViewDelegate {
    
    @IBOutlet weak var blackView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var back2msgrButton: UIButton!
    @IBOutlet weak var pauseImageView: PauseImageView!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    var fbSendButton: UIButton?
    var video: NSURL?
    var canvas: CanvasView?
    var playerView: PlayerView?
    
    var debug1timeInfiniteMode = false
    
    // MARK: - Preparations
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        back2msgrButton.hidden = true
        sendButton.hidden = true
        moreButton.hidden = true

        clearButton.layer.cornerRadius = 10
        moreButton.layer.cornerRadius = 10
        colorButton.layer.cornerRadius = 10

        colorButton.backgroundColor = UserDefaults.shared.lastColor

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "fromMessenger", name: "messengerURLHandler", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "backgrounded", name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func backgrounded() {
        if playerView?.repeatingCount > 0 {
            Analytics.track("backgroundedMVC", dimensions: ["playerRepeating": playerView?.repeatingCount])
        }
    }
    
    var alreadyWasDidAppear = false
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if alreadyWasDidAppear { return }
        alreadyWasDidAppear = true
        
        fbSendButton = FBSDKMessengerShareButton.circularButtonWithStyle(FBSDKMessengerShareButtonStyle.White, width: sendButton.frame.width)
        fbSendButton!.addTarget(self, action: Selector("sendTap:"), forControlEvents: UIControlEvents.TouchUpInside)
        self.sendButton.addSubview(fbSendButton!)
        
        initCanvas()
        Armchair.showPromptIfNecessary()
    }
    
    // MARK: - Navigation, Color Selection Delegates
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
        if let colorVC = segue.destinationViewController as? ColorSelectController {
            println("color segue")
//            canvas.timersPause()
            colorVC.selectedColor = canvas?.color
            colorVC.delegate = self
        }
    }

    @IBAction func unwindSegueToMainVC(segue: UIStoryboardSegue) { }
    
    func fromMessenger() {
        clearTap()
        back2msgrButton.hidden = false
    }
    
    func colorSelected(color: UIColor) {
        colorButton.backgroundColor = color
        canvas?.color = color
        UserDefaults.shared.lastColor = color
    }
    
    // MARK: - Canvas Init and Delegates
    
    func initCanvas() {
        deinitCanvas()
        
        var width = blackView.frame.width
        let m = width % 16
        if m != 0
        {
            width -= m
            println(width)
        }
        canvas = CanvasView(frame: CGRect(x: 0, y: 0, width: width, height: width))
        canvas?.center = blackView.center
        canvas?.delegate = self
        canvas?.color = UserDefaults.shared.lastColor
        self.view.insertSubview(canvas!, aboveSubview: blackView)

        if debug1timeInfiniteMode {
            canvas?.durFromLastTouch = 100
            canvas?.durMax = 100
        }
    }
    
    func deinitCanvas() {
        canvas?.delegate = nil
        canvas?.kill()
        canvas?.removeFromSuperview()
        canvas = nil
    }
    
    func canvasStartedFading() {
        colorButton.userInteractionEnabled = false
    }
    
    func canvasFinishedDrawing() {
        println(__FUNCTION__)
        spinner.startAnimating()
        canvas?.processVideo { (url) -> Void in
            self.spinner.stopAnimating()
            if url == nil
            {
                UIAlertView(title: "Ooops", message: "Something went wrong with the video saving. Please try again", delegate: nil, cancelButtonTitle: "OK").show()
                Analytics.track("err_MVC_video_saving")
                self.initCanvas()
                return
            }
            self.preparePlayer(url!)
        }
    }
    
    func canvasVRresumedOrStopped() {
        pauseImageView.stopAnimating()
    }
    
    func canvasVRpaused() {
        pauseImageView.startAnimating()
    }

    // MARK: - Player-related and delegates
    func preparePlayer(url: NSURL) {
        println(__FUNCTION__)
        video = url
        playerView = PlayerView(frame: canvas!.frame, videoURL: url, skip1frame: true)
        playerView?.delegate = self
        self.view.addSubview(playerView!)
        animateButtons(show: true)
        AdsHelper.shared.preloadInterstitial()
        UserDefaults.shared.refreshRemoteConfig()
        deinitCanvas()
    }
    
    func playerViewRepeatsVideo(count: Int) {
        if count <= UserDefaults.shared.adsInterstitialShowAfterPlayerRepeat {
            println("Player's \(count) repeat")
        }
        if count == UserDefaults.shared.adsInterstitialShowAfterPlayerRepeat {
            AdsHelper.shared.showInterstitial(self, doIfShowing: { () -> () in
                self.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    func stopPlayer() {
        playerView?.stopPlayer()
        playerView?.removeFromSuperview()
        playerView = nil
    }
    
    // MARK: - Animations
    func animateButtons(#show: Bool) {
        animateButtonShareVsColor(showShare: show)
        let b = self.sendButton
        if show {
            b.hidden = false
            b.transform = CGAffineTransformMakeScale(0,0)
            UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.5, options: .AllowUserInteraction, animations: { () -> Void in
                b.transform = CGAffineTransformIdentity
                }, completion: nil)
        } else {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                b.alpha = 0.0
            }, completion: { (finished) -> Void in
                b.hidden = true
                b.alpha = 1.0
            })
        }
    }
    
    func animateButtonShareVsColor(#showShare: Bool) {
        if !showShare && CGAffineTransformIsIdentity(self.colorButton.transform) { return }
        self.moreButton.hidden = false
        let moreT: CGAffineTransform
        let colorT: CGAffineTransform
        if showShare {
            self.moreButton.transform = CGAffineTransformMakeTranslation(-30-self.moreButton.frame.width, 0)
            moreT = CGAffineTransformIdentity
            colorT = CGAffineTransformMakeTranslation(-30-self.colorButton.frame.width, 0)
        } else {
            self.colorButton.transform = CGAffineTransformMakeTranslation(-30-self.colorButton.frame.width, 0)
            colorT = CGAffineTransformIdentity
            moreT = CGAffineTransformMakeTranslation(-30-self.moreButton.frame.width, 0)
        }
        UIView.animateWithDuration(0.8, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            if showShare { self.colorButton.transform = colorT } else { self.moreButton.transform = moreT }
        }, completion: nil)
        UIView.animateWithDuration(1.0, delay: 0.7, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            if !showShare { self.colorButton.transform = colorT } else { self.moreButton.transform = moreT }
        }, completion: nil)
        
    }
    
    // MARK: - UI Actions
    @IBAction func clearTap() {
        if debug1timeInfiniteMode {
            debug1timeInfiniteMode = false
            canvas?.finishDrawing()
            return
        }
        Analytics.track("clearTap", dimensions: ["playerRepeating": playerView?.repeatingCount, "wasRecording": canvas?.videoRecorder?.state == VideoRecorderState.Started])
        stopPlayer()
        video = nil
        initCanvas()
        animateButtons(show: false)
        colorButton.userInteractionEnabled = true
        pauseImageView.stopAnimating()
        spinner.stopAnimating()
    }

    @IBAction func colorTap(sender: AnyObject) {
        println("color tap")
        let state = canvas?.videoRecorder?.state                 // to save time, pause need to be executed first
        canvas?.timersPause()
        Analytics.track("colorTap", dimensions: ["wasRecording": state == .Started])
        self.performSegueWithIdentifier("main2color", sender: self)
    }
    
    @IBAction func sendTap(sender: AnyObject) {
        if video != nil {
            let result = FBSDKMessengerSharer.messengerPlatformCapabilities().rawValue & FBSDKMessengerPlatformCapability.Video.rawValue
            if result != 0 {
                // ok now share
                if let videoData = NSData(contentsOfURL: video!) {
                    let options = FBSDKMessengerShareOptions()
                    if let lastContext = lastMsgrContext where NSDate.timeIntervalSinceReferenceDate() - lastContext > UserDefaults.shared.fbOverrideContextTimeout {      // 15 minutes and new context
                        println("overriding fb context")
                        options.contextOverride = FBSDKMessengerBroadcastContext()
                    }
                    
                    FBSDKMessengerSharer.shareVideo(videoData, withOptions: options)
                    UserDefaults.shared.videosSent++
                    Armchair.userDidSignificantEvent(true)
                    Analytics.track("send", dimensions: ["playerRepeating": playerView?.repeatingCount, "videosSent": UserDefaults.shared.videosSent])
                    switch UserDefaults.shared.videosSent {
                    case Int(UserDefaults.shared.armchairSendsUntilPrompt):
                        Analytics.trackAchievement(desc: "rate")
                    case UserDefaults.shared.adsStartCount:
                        Analytics.trackAchievement(desc: "ads")
                    default:
                        break
                    }
                }
            } else {
                Analytics.track("err_send_not_installed", dimensions: ["playerRepeating": self.playerView?.repeatingCount])
                println("not installed then open link. Note simulator doesn't open iTunes store.")
                UIApplication.sharedApplication().openURL(NSURL(string: "itms://itunes.apple.com/us/app/facebook-messenger/id454638411?mt=8")!)
            }
        }
    }
    
    @IBAction func moreTap(sender: AnyObject) {
        let a = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let camRollAction = UIAlertAction(title: "Save to Camera Roll", style: UIAlertActionStyle.Default) { (_) -> Void in
            self.camRollTap()
        }
        a.addAction(camRollAction)
        let rateUsAction = UIAlertAction(title: "Rate us ⭐️⭐️⭐️⭐️⭐️", style: UIAlertActionStyle.Default) { (_) -> Void in
            Armchair.rateApp()
            Analytics.track("rateFromMenu")
        }
        a.addAction(rateUsAction)
        let inviteAction = UIAlertAction(title: "🎁 Invite friends 🎁", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            let content = FBSDKAppInviteContent()
            content.appLinkURL = NSURL(string: UserDefaults.shared.inviteUrl)!
            FBSDKAppInviteDialog.showWithContent(content, delegate: nil)
            Analytics.track("inviteFromMenu")
        })
        a.addAction(inviteAction)
        let fbPageAction = UIAlertAction(title: "Learn more...", style: UIAlertActionStyle.Default) { (_) -> Void in
            UIApplication.sharedApplication().openURL(NSURL(string: UserDefaults.shared.learnMorePageUrl)!)
            Analytics.track("learnMoreFromMenu")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        a.addAction(fbPageAction)
        #if DEBUG
            let debugAction = UIAlertAction(title: "🐛 DEBUG MENU 🐛", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
                self.debugMenuShow()
            })
            a.addAction(debugAction)
        #endif
        a.addAction(cancelAction)
        self.presentViewController(a, animated: true, completion: {
            Analytics.track("moreMenuOpened", dimensions: ["playerRepeating": self.playerView?.repeatingCount])
        })
    }
    
    func debugMenuShow() {
        let a = UIAlertController(title: "🐛 DEBUG MENU 🐛", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        let infiniteModeAction = UIAlertAction(title: "1-time ∞ mode", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.debug1timeInfiniteMode = true
            self.stopPlayer()
            self.video = nil
            self.initCanvas()
            self.animateButtons(show: false)
            self.colorButton.userInteractionEnabled = true
        })
        let showMsgrButtonAction = UIAlertAction(title: "Show back2msgr button", style: UIAlertActionStyle.Default) { (_) -> Void in
            self.back2msgrButton.hidden = false
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        a.addAction(infiniteModeAction)
        a.addAction(showMsgrButtonAction)
        a.addAction(cancelAction)
        self.presentViewController(a, animated: true, completion: nil)
    }
    
    func camRollTap() {
        if let v = video where UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(v.path!) {
            UISaveVideoAtPathToSavedPhotosAlbum(v.path!, self, Selector("camRollComplete:didFinishSavingWithError:contextInfo:"), nil)
        }
    }

    func camRollComplete(videoPath: String, didFinishSavingWithError: NSError?, contextInfo: UnsafeMutablePointer<Void>) {
        let text: String
        if didFinishSavingWithError == nil {
            text = "Saved to Camera Roll"
            Analytics.track("savedToCamRoll")
        } else {
            text = "No permissions for saving to Camera Roll"
            Analytics.track("err_saveToCamRoll")
        }
        let a = UIAlertController(title: nil, message: text, preferredStyle: UIAlertControllerStyle.Alert)
        self.presentViewController(a, animated: true) { () -> Void in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2e9)), dispatch_get_main_queue(), { () -> Void in
                a.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    @IBAction func backMsgrTap(sender: AnyObject) {
        Analytics.track("backMsgrTap", dimensions: ["playerRepeating": playerView?.repeatingCount, "wasRecording": canvas?.videoRecorder?.state == VideoRecorderState.Started])
        if FBSDKMessengerSharer.messengerPlatformCapabilities().rawValue & FBSDKMessengerPlatformCapability.Open.rawValue != 0 {
            FBSDKMessengerSharer.openMessenger()
        }
    }
    
}

