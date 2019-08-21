//
//  AVCompositionDebugViewer.m
//  AVCompositionDebugViewer
//
//  Created by Jonathan Lott on 5/20/18.
//

#import "AVCompositionDebugViewer.h"
#import "APLCompositionViewController.h"

#if TARGET_OS_OSX
@import AppKit;
#else
@import UIKit;
#endif
@import AVFoundation;

@implementation AVCompositionDebugViewer
+ (void)showCompositionDebugViewWithComposition:(AVMutableComposition *)composition videoComposition:(AVMutableVideoComposition *)videoComposition audioMix:(AVMutableAudioMix *)audioMix containerViewController: (UIViewController*)containerViewController {
    APLCompositionViewController* viewController = [[APLCompositionViewController alloc] initWithComposition:composition videoComposition:videoComposition audioMix:audioMix];
    
    if(!containerViewController) {
#if TARGET_OS_OSX
        NSWindow* window = [NSWindow windowWithContentViewController:viewController];
        [window makeKeyAndOrderFront:viewController];
        NSWindowController* windowController = [[NSWindowController alloc] initWithWindow:window];
        [windowController showWindow:viewController];
#endif
    }
    
    [containerViewController.view addSubview:viewController.view];
    [containerViewController addChildViewController:viewController];
    
    viewController.view.frame = containerViewController.view.bounds;
    if(containerViewController) {
        if (@available(macOS 10.11, iOS 9.0,  *)) {
            [NSLayoutConstraint activateConstraints:@[
                                                      [viewController.view.leadingAnchor constraintEqualToAnchor:containerViewController.view.leadingAnchor],
                                                      [viewController.view.trailingAnchor constraintEqualToAnchor:containerViewController.view.trailingAnchor],
                                                      [viewController.view.topAnchor constraintEqualToAnchor:containerViewController.view.topAnchor],
                                                      [viewController.view.bottomAnchor constraintEqualToAnchor:containerViewController.view.bottomAnchor]
                                                      ]];
        } else {
            
        }
    }
}
@end

