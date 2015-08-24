# Weave for Messenger

A one of my first indie projects.

![logo](appIcon_256_preRendered.png)

Weave for Messenger was inspired by Apple Watch sketch feature to quickly draw and send handcrafted doodles to peers. The app brings an enhanced version of Watch sketch feature to Facebook Messenger platform users. Weave animations are uploaded as standard videos viewable on any device with no app installed, repeating the way the doodle was drawn with a beautiful self-dissolving effect at the end of the recording.

Available on the App Store: https://itunes.apple.com/us/app/weave-for-messenger/id994829540?mt=8

Project fb page: https://www.facebook.com/weave4messenger

Developed using `Swift 1.2`

### Project highlights (what you can learn from it)

- Facebook Messenger integration with Compose/Reply flows, plus custom context time interval
- Autolayout with autosizing of all buttons ranging from 4[S] to 6 Plus
- `CanvasView`:
  - Smooth drawing using `CAShapeLayer`s with sequental caching using `NSOperation` with serial `NSOperationQueue` to improve performance and get rid of too many `CALayer`s
  - Drawn line animated from a different color and line width
  - self-dissolving serial animation of the whole sequence of `CAShapeLayer`s on the user's drawing timeout
- Video player with skipping of the first frame
- `VideoRecorder`:
  - multi-threaded screen capture using `CADisplayLink` and 2 `NSOperationQueue`s, first for capture and second for saving frames, highly optimized to minimize the usage of main thread
- Lots of spring and `CGAffineTransform` animations
- Simple analytics using Facebook Analytics
- `UserDefaults`:
  - one module to solve all configuration problems
  - remote configurable parameters via Parse.com `PFConfig` with default fallback values
  - storing runtime parameters to `NSUserDefaults` as simple variables via getter/setter
- Ability to remotely trigger interstitial advertisements with configurable app usage times, player repeats, interstitial-to-interstitial showing intervals

#### 3rd party integrations

- `Parse.com` for remote configuration
- `Armchair` for rating nags with remotely configurable parameters
- `Facebook SDK` for Messenger integration, analytics, invite friends feature
- `GoogleMobileAds` for remotely-triggered interstitial advertisements support
- `CEMovieMaker` for forming a video from a set of UIImages. https://github.com/cameronehrlich/CEMovieMaker

### Contact
Roman Shevtsov
https://twitter.com/ryushev

### License
MIT with DBAA notice
