//
//  APLCompositionViewController.m
//  AVCompositionDebugViewer
//
//  Created by Jonathan Lott on 8/20/19.
//

#import "APLCompositionViewController.h"
#import "APLCompositionDebugView.h"

#if TARGET_OS_OSX
@import Cocoa;
@import AVKit;
#define UIView NSView
#define UIViewController NSViewController
#else
@import UIKit;
//@import AssetsLibrary;
//@import MobileCoreServices;
#endif

@import AVFoundation;
@import CoreMedia;

/*
 Player view backed by an AVPlayerLayer
 */
#if TARGET_OS_OSX
@interface APLPlayerView : AVPlayerView
@end
@implementation APLPlayerView
@end
#else
@interface APLPlayerView : UIView

@property (nonatomic, retain) AVPlayer *player;

@end

@implementation APLPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
#endif

/*
 */

static NSString* const AVCDVPlayerViewControllerStatusObservationContext    = @"AVCDVPlayerViewControllerStatusObservationContext";
static NSString* const AVCDVPlayerViewControllerRateObservationContext = @"AVCDVPlayerViewControllerRateObservationContext";

@interface APLCompositionViewController ()
{
    BOOL            _playing;
    BOOL            _scrubInFlight;
    BOOL            _seekToZeroBeforePlaying;
    float            _lastScrubSliderValue;
    float            _playRateToRestore;
    id                _timeObserver;
}

@property AVPlayer                *player;
@property (nonatomic) AVPlayerItem            *playerItem;

@property (nonatomic, weak) IBOutlet APLPlayerView                *playerView;
@property (nonatomic, weak) IBOutlet APLCompositionDebugView    *compositionDebugView;

#if !TARGET_OS_OSX
@property (nonatomic, weak) IBOutlet UIToolbar                *toolbar;
@property (nonatomic, weak) IBOutlet UISlider                *scrubber;
@property (nonatomic, weak) IBOutlet UIBarButtonItem        *playPauseButton;
@property (nonatomic, weak) IBOutlet UILabel                *currentTimeLabel;

- (IBAction)togglePlayPause:(id)sender;

- (IBAction)beginScrubbing:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)endScrubbing:(id)sender;

- (void)updatePlayPauseButton;
- (void)updateScrubber;
- (void)updateTimeLabel;
#endif

- (CMTime)playerItemDuration;

- (void)synchronizePlayer;

@end

@implementation APLCompositionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
#if !TARGET_OS_OSX
    [self updateScrubber];
    [self updateTimeLabel];
#endif
    [self synchronize];
}
#if !TARGET_OS_OSX
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self viewDidAppear];
    
    [self addTimeObserverToPlayer];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeTimeObserverFromPlayer];

    [self viewWillDisappear];
}
#endif

- (void)viewDidAppear {
    if (!self.player) {
        _seekToZeroBeforePlaying = NO;
        self.player = [[AVPlayer alloc] init];
#if !TARGET_OS_OSX
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:(__bridge void *)(AVCDVPlayerViewControllerRateObservationContext)];
#endif
        [self.playerView setPlayer:self.player];
    }
    
    [self synchronizePlayer];
    
    // Set our AVPlayer and all composition objects on the AVCompositionDebugView
    self.compositionDebugView.player = self.player;
    [self.compositionDebugView synchronizeToComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
#if TARGET_OS_OSX
    [self.compositionDebugView needsDisplay];
#else
    [self.compositionDebugView setNeedsDisplay];
#endif
}

- (void)viewWillDisappear {
    [self.player pause];
}

#pragma mark - Setup

- (APLCompositionViewController*)initWithComposition:(AVMutableComposition *)composition videoComposition:(AVMutableVideoComposition *)videoComposition audioMix:(AVMutableAudioMix *)audioMix {
#if TARGET_OS_OSX
    NSString* nibName = @"APLCompositionViewController";
#else
    NSString* nibName = @"APLCompositionViewController-iOS";
#endif
    NSBundle* bundle = [NSBundle bundleForClass:[APLCompositionViewController class]];
    if(self = [super initWithNibName:nibName bundle:bundle]) {
        _composition = composition;
        _videoComposition = videoComposition;
        _audioMix = audioMix;
    }
    return self;
}


- (void)synchronizePlayer
{
    if ( self.player == nil )
        return;
    
    AVPlayerItem *playerItem = [self getPlayerItem];
    
    if (self.playerItem != playerItem) {
        if ( self.playerItem ) {
            [self.playerItem removeObserver:self forKeyPath:@"status"];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        }
        
        self.playerItem = playerItem;
#if !TARGET_OS_OSX
        if ( self.playerItem ) {
            // Observe the player item "status" key to determine when it is ready to play
            [self.playerItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial) context:(__bridge void *)(AVCDVPlayerViewControllerStatusObservationContext)];
            
            // When the player item has played to its end time we'll set a flag
            // so that the next time the play method is issued the player will
            // be reset to time zero first.
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        }
#endif
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
    }
}

- (void)synchronize
{
    // Build AVComposition and AVVideoComposition objects for playback
    [self synchronizePlayer];
    
    // Set our AVPlayer and all composition objects on the AVCompositionDebugView
    self.compositionDebugView.player = self.player;
    [self.compositionDebugView synchronizeToComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
#if TARGET_OS_OSX
    [self.compositionDebugView needsDisplay];
#else
    [self.compositionDebugView setNeedsDisplay];
#endif
    
}


- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.player currentItem];
    CMTime itemDuration = kCMTimeInvalid;
    
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        itemDuration = [playerItem duration];
    }
    
    /* Will be kCMTimeInvalid if the item is not ready to play. */
    return itemDuration;
}


- (AVPlayerItem *)getPlayerItem
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
    playerItem.videoComposition = self.videoComposition;
    playerItem.audioMix = self.audioMix;
    
    return playerItem;
}

#pragma mark - IOS Only

#if !TARGET_OS_OSX

#pragma mark - Utilities

/* Update the scrubber and time label periodically. */
- (void)addTimeObserverToPlayer
{
    if (_timeObserver)
        return;
    
    if (self.player == nil)
        return;
    
    if (self.player.currentItem.status != AVPlayerItemStatusReadyToPlay)
        return;
    
    double duration = CMTimeGetSeconds([self playerItemDuration]);
    
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth([self.scrubber bounds]);
        double interval = 0.5 * duration / width;
        
        /* The time label needs to update at least once per second. */
        if (interval > 1.0)
            interval = 1.0;
        __weak APLCompositionViewController *weakSelf = self;
        _timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:
                         ^(CMTime time) {
                             [weakSelf updateScrubber];
                             [weakSelf updateTimeLabel];
                         }];
    }
}

- (void)removeTimeObserverFromPlayer
{
    if (_timeObserver) {
        [self.player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == (__bridge void *)(AVCDVPlayerViewControllerRateObservationContext) ) {
        float newRate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        NSNumber *oldRateNum = [change objectForKey:NSKeyValueChangeOldKey];
        if ( [oldRateNum isKindOfClass:[NSNumber class]] && newRate != [oldRateNum floatValue] ) {
            _playing = ((newRate != 0.f) || (_playRateToRestore != 0.f));
            [self updatePlayPauseButton];
            [self updateScrubber];
            [self updateTimeLabel];
        }
    }
    else if ( context == (__bridge void *)(AVCDVPlayerViewControllerStatusObservationContext) ) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            /* Once the AVPlayerItem becomes ready to play, i.e.
             [playerItem status] == AVPlayerItemStatusReadyToPlay,
             its duration can be fetched from the item. */
            
            [self addTimeObserverToPlayer];
        }
        else if (playerItem.status == AVPlayerItemStatusFailed) {
            [self reportError:playerItem.error];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updatePlayPauseButton
{
    UIBarButtonSystemItem style = _playing ? UIBarButtonSystemItemPause : UIBarButtonSystemItemPlay;
    UIBarButtonItem *newPlayPauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:style target:self action:@selector(togglePlayPause:)];
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolbar.items];
    [items replaceObjectAtIndex:[items indexOfObject:self.playPauseButton] withObject:newPlayPauseButton];
    [self.toolbar setItems:items];
    
    self.playPauseButton = newPlayPauseButton;
}

- (void)updateTimeLabel
{
    double seconds = CMTimeGetSeconds([self.player currentTime]);
    if (!isfinite(seconds)) {
        seconds = 0;
    }
    
    int secondsInt = round(seconds);
    int minutes = secondsInt/60;
    secondsInt -= minutes*60;
    
    self.currentTimeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    self.currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%.2i:%.2i", minutes, secondsInt];
}

- (void)updateScrubber
{
    double duration = CMTimeGetSeconds([self playerItemDuration]);
    
    if (isfinite(duration)) {
        double time = CMTimeGetSeconds([self.player currentTime]);
        [self.scrubber setValue:time / duration];
    }
    else {
        [self.scrubber setValue:0.0];
    }
}

- (void)reportError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[error localizedDescription] message:[error localizedRecoverySuggestion] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    });
}

#pragma mark - IBActions

- (IBAction)togglePlayPause:(id)sender
{
    _playing = !_playing;
    if ( _playing ) {
        if ( _seekToZeroBeforePlaying ) {
            [self.player seekToTime:kCMTimeZero];
            _seekToZeroBeforePlaying = NO;
        }
        [self.player play];
    }
    else {
        [self.player pause];
    }
}

- (IBAction)beginScrubbing:(id)sender
{
    _seekToZeroBeforePlaying = NO;
    _playRateToRestore = [self.player rate];
    [self.player setRate:0.0];
    
    [self removeTimeObserverFromPlayer];
}

- (IBAction)scrub:(id)sender
{
    _lastScrubSliderValue = [self.scrubber value];
    
    if ( ! _scrubInFlight )
        [self scrubToSliderValue:_lastScrubSliderValue];
}

- (void)scrubToSliderValue:(float)sliderValue
{
    double duration = CMTimeGetSeconds([self playerItemDuration]);
    
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth([self.scrubber bounds]);
        
        double time = duration*sliderValue;
        double tolerance = 1.0f * duration / width;
        
        _scrubInFlight = YES;
        
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)
                toleranceBefore:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
                 toleranceAfter:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
              completionHandler:^(BOOL finished) {
                  self->_scrubInFlight = NO;
                  [self updateTimeLabel];
              }];
    }
}

- (IBAction)endScrubbing:(id)sender
{
    if ( _scrubInFlight )
        [self scrubToSliderValue:_lastScrubSliderValue];
    [self addTimeObserverToPlayer];
    
    [self.player setRate:_playRateToRestore];
    _playRateToRestore = 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    /* After the movie has played to its end time, seek back to time zero to play it again. */
    _seekToZeroBeforePlaying = YES;
}
#endif

@end
