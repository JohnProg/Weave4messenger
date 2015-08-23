//
//  PlayerView.swift
//  msgur
//
//  Created by Roman on 07/05/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import UIKit
import AVFoundation

protocol PlayerViewDelegate {
    func playerViewRepeatsVideo(count: Int)         // count means which repeat ended
}

enum PlayerViewState {
    case Playing, Stopped
}

class PlayerView: UIView {

    var playerLayer: AVPlayerLayer?
    
    var delegate: PlayerViewDelegate?
    
    var skip1frame = false
    var repeatingCount = 0                          // getting this var gets currently repeating number
    
    var state: PlayerViewState = .Stopped
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, videoURL: NSURL, skip1frame: Bool) {
        self.init(frame: frame)
        self.skip1frame = skip1frame
        preparePlayer(videoURL)
        UserDefaults.shared.countInits("PV")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        UserDefaults.shared.countDeinits("PV")
    }
    
    func preparePlayer(url: NSURL) {
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers, error: nil)
        let player = AVPlayer(URL: url)
        player.muted = true
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = self.bounds
        playerLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.layer.addSublayer(playerLayer)
        repeatingCount = 0
        restartVideoFromBeginning()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "restartVideoFromBeginning", name: AVPlayerItemDidPlayToEndTimeNotification, object: player.currentItem)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resumeAppActive", name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resumeAppActive", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func restartVideoFromBeginning() {
        if skip1frame {
            let timeScale = playerLayer?.player.currentItem.asset.duration.timescale
            playerLayer?.player.seekToTime(CMTimeMakeWithSeconds(0.135, timeScale!), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        } else {
            playerLayer?.player.seekToTime(CMTimeMake(0, 1))
        }
        state = .Playing
        playerLayer?.player.play()
        self.delegate?.playerViewRepeatsVideo(repeatingCount)
        repeatingCount++
    }
    
    func stopPlayer() {
        state = .Stopped
        NSNotificationCenter.defaultCenter().removeObserver(self)
        playerLayer?.player.pause()
        playerLayer?.removeFromSuperlayer()
        playerLayer?.player = nil
        playerLayer = nil
    }

    func resumeAppActive() {
        state = .Playing
        playerLayer?.player.play()
    }
    
}
