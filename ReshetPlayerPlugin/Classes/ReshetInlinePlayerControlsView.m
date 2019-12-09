//
//  ReshetInlinePlayerControlsView.m
//  Zapp-App
//
//  Created by Roi kedarya on 09/12/2019.
//  Copyright © 2017 Applicaster LTD. All rights reserved.
//

@import ZappPlugins;
@import ApplicasterSDK;

#import "ReshetInlinePlayerControlsView.h"

@interface ReshetInlinePlayerControlsView ()
@property (nonatomic, assign) BOOL animatingControlsFade;
@property (nonatomic, assign) BOOL playerControlsContainerHidden;
@property (nonatomic, strong) NSDictionary *playingItemInfo;

@end

@implementation ReshetInlinePlayerControlsView

@synthesize volumeView = _volumeView;
@synthesize playButton;
@synthesize pauseButton;
@synthesize seekSlider;
@synthesize expandButton;
@synthesize nativeShareButton;

#pragma mark - UIView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.volumeView.showsVolumeSlider = NO;
    [self.volumeView sizeToFit];
    [self setStylesForControls];
    self.playerControlsContainerHidden = YES;
    self.expandButton.hidden = NO;
}

#pragma mark - public

#pragma mark - private

- (void)customizeSeekSliderView:(UISlider *)slider
{
    [slider setThumbImage:[APApplicasterResourcesHelper imageNamed:@"inline_player_slider_dot"] forState:UIControlStateNormal];
    
    if ([slider isKindOfClass:[APSlider class]]) {
        UIImage *breakpointImage = [UIImage imageFromColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] andSize:CGSizeMake(6, 3)];
        [((APSlider *)slider).breakpointsView setBreakpointImage:breakpointImage];
    }
}

- (void)setStylesForControls
{
    [self.topGradientView setStartColor:[UIColor colorWithRed:1.0/256.0 green:2.0/256.0 blue:2.0/256.0 alpha:0.3]];
    [self.topGradientView setEndColor:[UIColor colorWithRed:1.0/256.0 green:2.0/256.0 blue:2.0/256.0 alpha:0.0]];
    [self.topGradientView setOrientation:APGradientViewVertical];
    self.topGradientView.shouldClickThrough = YES;
    
    [self.bottomGradientView setStartColor:[UIColor colorWithRed:1.0/256.0 green:2.0/256.0 blue:2.0/256.0 alpha:0.0]];
    [self.bottomGradientView setEndColor:[UIColor colorWithRed:1.0/256.0 green:2.0/256.0 blue:2.0/256.0 alpha:0.3]];
    [self.bottomGradientView setOrientation:APGradientViewVertical];
    self.bottomGradientView.shouldClickThrough = YES;
    
    [self.playButton setImage:[APApplicasterResourcesHelper imageNamed:@"inline_player_play_button"] forState:UIControlStateNormal];
    [self.playButton setImage:[APApplicasterResourcesHelper imageNamed:@"inline_player_play_button"] forState:UIControlStateHighlighted];

//     Pause button asset not right
    [self.pauseButton setImage:[APApplicasterResourcesHelper imageNamed:@"inline_player_pause_button"] forState:UIControlStateNormal];
    [self.pauseButton setImage:[APApplicasterResourcesHelper imageNamed:@"inline_player_pause_button"] forState:UIControlStateHighlighted];
//
    [self.expandButton setImage:[APApplicasterResourcesHelper imageNamed:@"inline_player_FullScreen_button"] forState:UIControlStateNormal];
    [self.expandButton setImage:[APApplicasterResourcesHelper imageNamed:@"inline_player_FullScreen_button"] forState:UIControlStateHighlighted];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // Make self unhittable
    if (hitView == self)
    {
        hitView = nil;
    }
    
    return hitView;
}

#pragma mark - player controls

- (void)show:(BOOL)animated
{
    if (self.animatingControlsFade == NO && animated) {
        self.animatingControlsFade = YES;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.playerControlsContainer.alpha = 1.0;
                         } completion:^(BOOL finished) {
                             self.playerControlsContainerHidden = NO;
                             self.animatingControlsFade = NO;
                         }];
    } else {
        self.playerControlsContainer.alpha = 1.0;
        self.playerControlsContainerHidden = NO;
    }
}

- (void)hide:(BOOL)animated
{
    if (self.animatingControlsFade == NO && animated) {
        self.animatingControlsFade = YES;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.playerControlsContainer.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             self.playerControlsContainerHidden = YES;
                             self.animatingControlsFade = NO;
                         }];
    } else {
        self.playerControlsContainer.alpha = 0.0;
        self.playerControlsContainerHidden = YES;
    }
}

- (BOOL)isVisible
{
    return !self.playerControlsContainerHidden;
}

- (void)setDuration:(NSTimeInterval)duration
{
    self.totalTimeLabel.text = [NSString timeCodeWithSeconds:duration];
    
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    self.currentTimeLabel.text = [NSString timeCodeWithSeconds:currentTime];
}

- (void)videoContentDidStartPlayingWithItem:(NSDictionary *)playingItemInfo
{
    self.playingItemInfo = playingItemInfo;
}

-(void)updateControlsForLiveState:(BOOL)isLive
{
    self.seekSlider.hidden = isLive;
    self.currentTimeLabel.hidden = isLive;
    self.totalTimeLabel.hidden = isLive;
}

+ (ReshetInlinePlayerControlsView *)playerControls
{
    return [[NSBundle bundleForClass:self.class] loadNibNamed:@"ReshetInlinePlayerControlsView"
                                                        owner:self
                                                      options:nil].firstObject;
}

@end
