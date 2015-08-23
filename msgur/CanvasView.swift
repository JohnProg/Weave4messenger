//
//  CanvasView.swift
//  msgur
//
//  Created by asdfgh1 on 20/04/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import UIKit
import Parse

protocol CanvasViewDelegate {
    func canvasFinishedDrawing()
    func canvasStartedFading()
    func canvasVRpaused()
    func canvasVRresumedOrStopped()
}

class CanvasView: UIView {

    lazy var cacheQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Cache queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = NSQualityOfService.UserInteractive
        return queue
        }()
    
    var finishedDrawing = true {
        willSet {
            if newValue == true { cacheQueue.cancelAllOperations() }
        }
    }
    
    var durMax = 15.0
    var durFromLastTouch = 2.0
    let normalLineWidth: CGFloat = 7.0
    let bgColor = UIColor.blackColor()
    var color = UIColor.whiteColor()
    
    var shapeLayers: [CAShapeLayer] = []
    var cacheImg: UIImage?
    var points = [CGPoint](count: 5, repeatedValue: CGPointZero)
    var pointsCtr = 0
    
    var gestureRecognizerPan: UIPanGestureRecognizer?
    var gestureRecognizerTap: UITapGestureRecognizer?
    var timerMax: NSTimer?
    var timerFromLastTouch: NSTimer?
    var videoRecorder: VideoRecorder?
    var delegate: CanvasViewDelegate?
    var killSwitch = false

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = bgColor
        self.multipleTouchEnabled = false
        self.layer.drawsAsynchronously = true
        self.clearsContextBeforeDrawing = false
        
        videoRecorder = VideoRecorder(view: self)
        gestureRecognizerPan = UIPanGestureRecognizer(target: self, action: Selector("handlePan:"))
        gestureRecognizerPan?.maximumNumberOfTouches = 1
        gestureRecognizerTap = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
        self.addGestureRecognizer(gestureRecognizerPan!)
        self.addGestureRecognizer(gestureRecognizerTap!)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "pauseWhenBackgrounded", name: UIApplicationWillResignActiveNotification, object: nil)
        
        UserDefaults.shared.countInits("CV")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        cacheQueue.cancelAllOperations()
        UserDefaults.shared.countDeinits("CV")
    }
    
    func kill() {
        killSwitch = true
        finishDrawing()
    }
    
    func pointOutOfBounds(inout point: CGPoint) -> Bool {
        var result = false
        let halfLine = CGFloat(normalLineWidth / 2)
        if (point.x > (self.bounds.width - halfLine))
        {
            result = true
            point.x = self.bounds.width - halfLine
        }
        if (point.y > (self.bounds.height - halfLine))
        {
            result = true
            point.y = (self.bounds.height - halfLine)
        }
        if (point.x < halfLine)
        {
            result = true
            point.x = halfLine
        }
        if (point.y < halfLine)
        {
            result = true
            point.y = halfLine
        }
        return result
    }
    
    var wasOutOfBounds = false
    
    func startVRandTimersIfNeeded() {
        if shapeLayers.isEmpty || lastTimerMaxBeforePause != nil {
            let dur = lastTimerMaxBeforePause != nil ? lastTimerMaxBeforePause!+0.5 : durMax
            lastTimerMaxBeforePause = nil
            timerMax = NSTimer.scheduledTimerWithTimeInterval(dur, repeats: false) { (_) -> (Void) in
                println("timerMax")
                self.finishDrawing()
            }
            videoRecorder?.start()
            self.delegate?.canvasVRresumedOrStopped()
            finishedDrawing = false
        }
    }
    
    func handlePan(gesture: UIPanGestureRecognizer) {
        var point = gesture.locationInView(self)
        switch gesture.state {
        case .Began:
            println("got began")
            pointsCtr = 0
            points[pointsCtr] = point
            wasOutOfBounds = false
        case .Changed, .Ended, .Cancelled:
            if gesture.state == .Ended {
                println("got ended")
                if !wasOutOfBounds && point.x < 0 && point.y < 0 {
                    println("CV IGNORING BUGGY TOUCHENDED")
                    Analytics.track("err_CV_buggy_touchEnded")
                    return
                }
            }
            
            var drawIt = true
            if pointOutOfBounds(&point) || gesture.state == .Cancelled {
                if wasOutOfBounds {
                    drawIt = false
                } else {
                    while pointsCtr < 3 {
                        pointsCtr++
                        points[pointsCtr] = point
                    }
                    wasOutOfBounds = true
                }
            } else {
                wasOutOfBounds = false
            }
            pointsCtr++
            points[pointsCtr] = point
            if pointsCtr == 4 {
                points[3] = CGPointMake((points[2].x + points[4].x) / 2.0, (points[2].y + points[4].y) / 2.0)
                let path = UIBezierPath()
                path.moveToPoint(points[0])
                if drawIt {
                    path.addCurveToPoint(points[3], controlPoint1: points[1], controlPoint2: points[2])
                    startVRandTimersIfNeeded()
                    drawShapeLayerWithAnimation(path)
                }
                
                points[0] = points[3]
                points[1] = points[4]
                pointsCtr = 1

                timerFromLastTouchProlong()
            }
            
            if gesture.state == .Cancelled && !finishedDrawing {
                if let tm = timerMax where tm.valid {
                    println("got Cancelled")
                    timersPause()
                }
            }

        default:
            println("got other")

        }
    }
    
    func timerFromLastTouchProlong() {
        timerFromLastTouch?.invalidate()
        timerFromLastTouch = NSTimer.scheduledTimerWithTimeInterval(durFromLastTouch, repeats: false, handler: { (_) -> (Void) in
            self.finishDrawing()
        })
    }
    
    func drawShapeLayerWithAnimation(path: UIBezierPath) {
        let sl = CAShapeLayer()
        sl.path = path.CGPath
        sl.lineCap = kCALineCapRound
        sl.strokeColor = color.CGColor
        sl.lineWidth = normalLineWidth
        sl.fillColor = UIColor.clearColor().CGColor
        self.layer.addSublayer(sl)
        let duration: CFTimeInterval
        if !UserDefaults.shared.isSlowDevice {
            duration = 0.5
            let animColor = CABasicAnimation(keyPath: "strokeColor")
            animColor.fromValue = UIColor.whiteColor().CGColor
            animColor.toValue = color.CGColor
            let animWidth = CABasicAnimation(keyPath: "lineWidth")
            animWidth.fromValue = 12.0
            animWidth.toValue = normalLineWidth
            let animGroup = CAAnimationGroup()
            animGroup.animations = [animColor, animWidth]
            animGroup.fillMode = kCAFillModeBoth
            animGroup.removedOnCompletion = false
            animGroup.duration = duration
            sl.drawsAsynchronously = true
            sl.addAnimation(animGroup, forKey: "blabla")
        } else {
            duration = 0
        }
        
        shapeLayers.append(sl)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(duration * 1e+9)), dispatch_get_main_queue()) { () -> Void in
            if !self.finishedDrawing { self.cacheQueue.addOperation(CanvasViewCache(canvas: self, sl: sl)) }
        }

    }
    
    func handleTap(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            var point = gesture.locationInView(self)
            let path = UIBezierPath(arcCenter: point, radius: normalLineWidth / 1.5, startAngle: CGFloat(0), endAngle: CGFloat(M_PI*2), clockwise: true)
            startVRandTimersIfNeeded()
            drawShapeLayerWithAnimation(path)
            timerFromLastTouchProlong()
        }
    }
        
    func finishDrawing() {
        finishedDrawing = true
        gestureRecognizerPan?.enabled = false
        gestureRecognizerTap?.enabled = false
        timerMax?.invalidate()
        timerFromLastTouch?.invalidate()
        if killSwitch {
            self.videoRecorder?.stop()
            return
        }
        
        println("FINISH")
        println(shapeLayers.count)
        println(self.layer.sublayers)
        
        self.layer.contents = nil
        for layer in shapeLayers {
            layer.removeFromSuperlayer()
        }
        self.delegate?.canvasStartedFading()
        
        var timer = 0.0
        let animDuration = 0.5
        for (i,layer) in enumerate(shapeLayers) {
            self.layer.addSublayer(layer)
            let animColor = CABasicAnimation(keyPath: "strokeColor")
            animColor.toValue = bgColor.CGColor
            let animWidth = CABasicAnimation(keyPath: "lineWidth")
            animWidth.fromValue = normalLineWidth
            animWidth.toValue = 0.0
            let animGroup = CAAnimationGroup()
            animGroup.animations = [animColor, animWidth]
            animGroup.fillMode = kCAFillModeBoth
            animGroup.removedOnCompletion = false
            animGroup.duration = animDuration
            animGroup.beginTime = CACurrentMediaTime() + timer
            layer.addAnimation(animGroup, forKey: "finish")
            timer+=0.03
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((timer + animDuration) * 1e+9)), dispatch_get_main_queue()) { () -> Void in
            self.videoRecorder?.stop()
            if self.killSwitch { return }
            self.delegate?.canvasVRresumedOrStopped()
            self.delegate?.canvasFinishedDrawing()
        }
    }
    
    func processVideo(completion: (NSURL?) -> Void) {
        videoRecorder?.saveVideo({ (url) -> Void in
            if self.killSwitch { return }
            completion(url)
        })
    }
    
    var lastTimerMaxBeforePause: NSTimeInterval?
    
    func timersPause() {
        println("timers pause")
        timerFromLastTouch?.invalidate()
        if let tM = timerMax where tM.valid { lastTimerMaxBeforePause = timerMax?.fireDate.timeIntervalSinceNow }
        timerMax?.invalidate()
        videoRecorder?.stop()
        if !shapeLayers.isEmpty { self.delegate?.canvasVRpaused() }
    }
    
    func pauseWhenBackgrounded() {
        if !finishedDrawing {
            if let tm = timerMax where tm.valid {
                println("got Backgrounded")
                timersPause()
            }
        }
    }
    
}

class CanvasViewCache: NSOperation {
    let canvas: CanvasView
    let sl: CAShapeLayer
    
    init(canvas: CanvasView, sl: CAShapeLayer) {
        self.canvas = canvas
        self.sl = sl
    }
    
    override func main() {
        if self.cancelled { return }
        UIGraphicsBeginImageContextWithOptions(canvas.bounds.size, true, 0.0)
        let ctx = UIGraphicsGetCurrentContext()
//        CGContextSetBlendMode(ctx, kCGBlendModeCopy)
        if canvas.cacheImg == nil {
            canvas.bgColor.setFill()
            CGContextFillRect(ctx, canvas.bounds)
        } else {
            canvas.cacheImg?.drawAtPoint(CGPointZero)
        }
        sl.renderInContext(ctx)
        canvas.cacheImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if self.cancelled { return }
        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
            if self.cancelled { return }
            self.sl.removeFromSuperlayer()
            self.canvas.layer.contents = self.canvas.cacheImg!.CGImage
        })
    }
    
}
