//
//  VideoRecorder.swift
//  msgur
//
//  Created by asdfgh1 on 24/04/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import Foundation
import Parse

enum VideoRecorderState {
    case Started, Stopped
}

class VideoRecorder: NSObject {
    lazy var captureQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Capture queue"
        queue.qualityOfService = NSQualityOfService.UserInteractive
        return queue
        }()
    lazy var saveQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Save queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = NSQualityOfService.UserInteractive
        return queue
        }()

    var displayLink: CADisplayLink?
    
    var frames: [UIImage] = []
    
    weak var view: UIView?
    
    var state: VideoRecorderState = .Stopped
    
    init(view: UIView) {
        self.view = view
        super.init()
        UserDefaults.shared.countInits("VR")
    }
    
    deinit {
        displayLink?.invalidate()
        displayLink = nil
        captureQueue.cancelAllOperations()
        saveQueue.cancelAllOperations()
        frames.removeAll(keepCapacity: false)
        UserDefaults.shared.countDeinits("VR")
    }
    
    func start() {
        if state == .Started {
            println("VR double start, skipping")
            Analytics.track("err_VR_double_start")
            return
        }
        println("VR start")
        state = .Started
        displayLink = CADisplayLink(target: self, selector: Selector("handleDL:"))
        displayLink?.frameInterval = 4
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func stop() {
        println("VR stop")
        state = .Stopped
        displayLink?.invalidate()
        displayLink = nil
        println("VR frames: \(frames.count)")
    }
    
    func handleDL(displayLink: CADisplayLink) {
        if let view = view {
            captureQueue.addOperation(VideoRecorderCaptureFrame(parentVR: self, parentView: view))
        }
    }
    
    func saveVideo(completion: (NSURL?) -> Void) {
        if state != .Stopped {
            println("VR must be stopped before saving, exiting")
            Analytics.track("err_VR_not_stopped_before_saving")
            return
        }
        captureQueue.cancelAllOperations()
        saveQueue.cancelAllOperations()

        if frames.isEmpty {
            completion(nil)
            return
        }
        
        if let frame1 = UIImage(named: "frame1.png") {
            println("got frame 1")
            frames.insert(resizeImage(frame1, size: frames.last!.size), atIndex: 0)
        }
        
        let settings = CEMovieMaker.videoSettingsWithCodec(AVVideoCodecH264, withWidth: frames.last!.size.width, andHeight: frames.last!.size.height)
        let movieMaker = CEMovieMaker(settings: settings)
        
        movieMaker.createMovieFromImages(frames, withCompletion: { (url) -> Void in
            println(url)
            completion(url)
        })

        frames.removeAll(keepCapacity: false)
    }
    
    func resizeImage(image: UIImage, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
}

class VideoRecorderCaptureFrame: NSOperation {
    let videoRecorder: VideoRecorder
    let view: UIView
    
    init(parentVR: VideoRecorder, parentView: UIView) {
        self.videoRecorder = parentVR
        self.view = parentView
    }
    
    override func main() {
        if self.cancelled { return }
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, true, 0.0) // uiscreen mainscreen scale
        var ctx = UIGraphicsGetCurrentContext()
        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
            UIGraphicsPushContext(ctx)
            self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: false)
            UIGraphicsPopContext()
        })
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if self.cancelled { return }
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, true, 1.0)
        ctx = UIGraphicsGetCurrentContext()
        image.drawAtPoint(CGPointZero)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if self.cancelled { return }
        self.videoRecorder.saveQueue.addOperationWithBlock { () -> Void in
            self.videoRecorder.frames.append(scaledImage)
        }
    }
    
}

