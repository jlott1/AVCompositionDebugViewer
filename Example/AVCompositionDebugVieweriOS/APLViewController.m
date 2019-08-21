/*
 File: APLViewController.m
 Abstract: UIViewController subclass setups playback of AVMutableComposition and also initializes an APLCompositionDebugView which then represents the underlying composition, video composition and audio mix. It also handles the user interaction with UISlider and UIBarButtonItems.
 Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "APLViewController.h"
#import "APLSimpleEditor.h"
#import "APLCompositionDebugView.h"

@import AVFoundation;
@import AVCompositionDebugViewer;

@interface APLViewController ()
{
    float            _transitionDuration;
    BOOL            _transitionsEnabled;
}

@property APLSimpleEditor        *editor;
@property NSMutableArray        *clips;
@property NSMutableArray        *clipTimeRanges;

- (void)synchronizePlayerWithEditor;

@end

@implementation APLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.editor = [[APLSimpleEditor alloc] init];
    self.clips = [[NSMutableArray alloc] initWithCapacity:2];
    self.clipTimeRanges = [[NSMutableArray alloc] initWithCapacity:2];
    
    // Defaults for the transition settings.
    _transitionDuration = 2.0;
    _transitionsEnabled = YES;
        
    // Add the clips from the main bundle to create a composition using them
    [self setupEditingAndPlayback];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    // Build AVComposition and AVVideoComposition objects for playback
    [self.editor buildCompositionObjectsForPlayback];
    [self synchronizePlayerWithEditor];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)synchronizePlayerWithEditor {
    [AVCompositionDebugViewer showCompositionDebugViewWithComposition:self.editor.composition videoComposition:self.editor.videoComposition audioMix:self.editor.audioMix containerViewController:self];
}
#pragma mark - Simple Editor

- (void)setupEditingAndPlayback
{
    AVURLAsset *asset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SharedResources/sample_clip1" ofType:@"m4v"]]];
    AVURLAsset *asset2 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SharedResources/sample_clip2" ofType:@"mov"]]];
    
    dispatch_group_t dispatchGroup = dispatch_group_create();
    NSArray *assetKeysToLoadAndTest = @[@"tracks", @"duration", @"composable"];
    
    [self loadAsset:asset1 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
    [self loadAsset:asset2 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
    
    // Wait until both assets are loaded
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^(){
        [self synchronizeWithEditor];
    });
}

- (void)loadAsset:(AVAsset *)asset withKeys:(NSArray *)assetKeysToLoad usingDispatchGroup:(dispatch_group_t)dispatchGroup
{
    dispatch_group_enter(dispatchGroup);
    [asset loadValuesAsynchronouslyForKeys:assetKeysToLoad completionHandler:^(){
        // First test whether the values of each of the keys we need have been successfully loaded.
        for (NSString *key in assetKeysToLoad) {
            NSError *error;
            
            if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                NSLog(@"Key value loading failed for key:%@ with error: %@", key, error);
                goto bail;
            }
        }
        if (![asset isComposable]) {
            NSLog(@"Asset is not composable");
            goto bail;
        }
        
        [self.clips addObject:asset];
        // This code assumes that both assets are atleast 5 seconds long.
        [self.clipTimeRanges addObject:[NSValue valueWithCMTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), CMTimeMakeWithSeconds(5, 1))]];
    bail:
        dispatch_group_leave(dispatchGroup);
    }];
}

- (void)synchronizeWithEditor
{
    // Clips
    [self synchronizeEditorClipsWithOurClips];
    [self synchronizeEditorClipTimeRangesWithOurClipTimeRanges];
    
    
    // Transitions
    if (_transitionsEnabled) {
        self.editor.transitionDuration = CMTimeMakeWithSeconds(_transitionDuration, 600);
    } else {
        self.editor.transitionDuration = kCMTimeInvalid;
    }
    
    // Build AVComposition and AVVideoComposition objects for playback
    [self.editor buildCompositionObjectsForPlayback];
    [self synchronizePlayerWithEditor];
    
}

- (void)synchronizeEditorClipsWithOurClips
{
    NSMutableArray *validClips = [NSMutableArray arrayWithCapacity:2];
    for (AVURLAsset *asset in self.clips) {
        if (![asset isKindOfClass:[NSNull class]]) {
            [validClips addObject:asset];
        }
    }
    
    self.editor.clips = validClips;
}

- (void)synchronizeEditorClipTimeRangesWithOurClipTimeRanges
{
    NSMutableArray *validClipTimeRanges = [NSMutableArray arrayWithCapacity:2];
    for (NSValue *timeRange in self.clipTimeRanges) {
        if (! [timeRange isKindOfClass:[NSNull class]]) {
            [validClipTimeRanges addObject:timeRange];
        }
    }
    
    self.editor.clipTimeRanges = validClipTimeRanges;
}
@end
