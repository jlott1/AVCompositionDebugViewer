//
//  AVCompositionDebugViewer.h
//  AVCompositionDebugViewer
//
//  Created by Jonathan Lott on 5/20/18.
//

@import Foundation;
@import AVFoundation;
#if TARGET_OS_OSX
@import Cocoa;
#define UIViewController NSViewController
#else
@import UIKit;
#endif

@interface AVCompositionDebugViewer : NSObject

+ (void)showCompositionDebugViewWithComposition:(AVMutableComposition *)composition videoComposition:(AVMutableVideoComposition *)videoComposition audioMix:(AVMutableAudioMix *)audioMix containerViewController: (UIViewController*)containerViewController;
@end
