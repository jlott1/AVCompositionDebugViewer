//
//  APLCompositionViewController.h
//  AVCompositionDebugViewer
//
//  Created by Jonathan Lott on 8/20/19.
//

@import Foundation;
@import AVFoundation;

#if TARGET_OS_OSX
@import AppKit;
#else
@import UIKit;
#endif


#if TARGET_OS_OSX
@interface APLCompositionViewController : NSViewController
#else
@interface APLCompositionViewController : UIViewController
#endif
@property (nonatomic, readonly, retain) AVMutableComposition *composition;
@property (nonatomic, readonly, retain) AVMutableVideoComposition *videoComposition;
@property (nonatomic, readonly, retain) AVMutableAudioMix *audioMix;
- (AVPlayerItem *)getPlayerItem;
- (APLCompositionViewController*)initWithComposition:(AVMutableComposition *)composition videoComposition:(AVMutableVideoComposition *)videoComposition audioMix:(AVMutableAudioMix *)audioMix;
@end
