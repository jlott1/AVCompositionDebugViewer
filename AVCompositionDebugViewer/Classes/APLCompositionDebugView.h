//
//  APLCompositionDebugView.h
//  AVCompositionDebugViewer
//
//  Created by Jonathan Lott on 5/20/18.
//

@import Foundation;

#if TARGET_OS_OSX
@import Cocoa;
#define UIView NSView
#else
@import UIKit;
#endif

#import <CoreMedia/CMTime.h>
#import <AVFoundation/AVFoundation.h>

@interface APLCompositionDebugView : UIView
{
@private
    CALayer *drawingLayer;
    CMTime    duration;
    CGFloat compositionRectWidth;
    
    NSArray *compositionTracks;
    NSArray *audioMixTracks;
    NSArray *videoCompositionStages;
    
    CGFloat scaledDurationToWidth;
}

@property AVPlayer *player;

- (void)synchronizeToComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

@end
