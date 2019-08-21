# AVCompositionDebugViewer

[![CI Status](https://img.shields.io/travis/jlott1/AVCompositionDebugViewer.svg?style=flat)](https://travis-ci.org/jlott1/AVCompositionDebugViewer)
[![Version](https://img.shields.io/cocoapods/v/AVCompositionDebugViewer.svg?style=flat)](https://cocoapods.org/pods/AVCompositionDebugViewer)
[![License](https://img.shields.io/cocoapods/l/AVCompositionDebugViewer.svg?style=flat)](https://cocoapods.org/pods/AVCompositionDebugViewer)
[![Platform](https://img.shields.io/cocoapods/p/AVCompositionDebugViewer.svg?style=flat)](https://cocoapods.org/pods/AVCompositionDebugViewer)

AVFoundation and AVComposition debugging viewer. Borrowed from Apple sample project and converted to cocoapod.  Allows you to create a custom AVMutableComposition and visualize it in the debugger view

## How To Use

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Works great in Swift or Objective-C:

Just create a custom `AVMutableComposition` with optional `AVMutableVideoComposition` and `AVMutableAudioMix` and pass it to the `AVCompositionDebugViewer`

```
import AVCompositionDebugViewer
                    
AVCompositionDebugViewer.showCompositionDebugView(with: avComposition, videoComposition: videoComposition, audioMix: audioMix, containerViewController: viewController)

```

On Mac:  If you pass `nil` for parameter `containerViewController` then a new window will popup with the debug view controller automatically.

On iOS: You must specify a `containerViewController` to contain the composition debug view controller

## Requirements

None.  Works on Mac and iOS with AVFoundation

See Apple Docs for more info: 


[Technical Note TN2447: 
Debugging AVFoundation Compositions, Video Compositions, and Audio Mixes](https://developer.apple.com/library/archive/technotes/tn2447/_index.html)

[Apple's AVCompositionDebugViewer(Mac) code](https://developer.apple.com/library/content/samplecode/AVCompositionDebugViewer/)


[Apple's AVCompositionDebugViewer(iOS) code](https://developer.apple.com/library/content/samplecode/AVCompositionDebugVieweriOS/Introduction/Intro.html#//apple_ref/doc/uid/DTS40013421)
## Installation

AVCompositionDebugViewer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AVCompositionDebugViewer'
```

## Author

Jonathan Lott

## License

AVCompositionDebugViewer is available under the MIT license. See the LICENSE file for more info.
