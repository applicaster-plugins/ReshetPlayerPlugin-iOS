//
//  ReshetPlayerControlsView.m
//  ReshetPlayerPlugin
//
//  Created by Roi Kedarya on 03/12/2019.
//

#import "ReshetPlayerControlsView.h"

@import ZappPlugins;

@implementation ReshetPlayerControlsView

@synthesize seekSlider;
@synthesize stopButton;
@synthesize volumeView = _volumeView;
@synthesize nativeShareButton;
@synthesize subtitlesButton;
@synthesize chromecastButton;




- (void)awakeFromNib
{
    [super awakeFromNib];
    self.seekSlider.delegate = self;
    self.volumeView.showsVolumeSlider = NO;
    [self.volumeView sizeToFit];
    [self setStylesForControls];
}

- (void)customizeSeekSliderView:(ReshetSlider *)slider
{
    slider.minimumTrackTintColor = [ZAAppConnector.sharedInstance.layoutsStylesDelegate styleColorForKey:@"PlayerControlsViewSliderMinimumTintColor"];
    slider.minimumTrackTintColor = [ZAAppConnector.sharedInstance.layoutsStylesDelegate styleColorForKey:@"PlayerControlsViewSliderMaximumTintColor"];
    [slider setThumbImage:[APApplicasterResourcesHelper imageNamed:@"player_knob"] forState:UIControlStateNormal];
    
    if ([slider isKindOfClass:[APSlider class]]) {
        UIImage *breakpointImage = [UIImage imageFromColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] andSize:CGSizeMake(6, 3)];
        [((APSlider *)slider).breakpointsView setBreakpointImage:breakpointImage];
    }
}

#pragma mark - Private

- (void)setStylesForControls
{
    //[_timeLabel setLabelStyleForKey:PlayerControlsViewTimeLabel];
    
    //_backgroundImageView.image = [GAResourceHelper imageNamed:@"player_background_tile"];
    
    [self.stopButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_back_btn"] forState:UIControlStateNormal];
    [self.stopButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_back_btn_selected"] forState:UIControlStateHighlighted];
    
    [self.playButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_play_btn"] forState:UIControlStateNormal];
    [self.playButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_play_btn_selected"] forState:UIControlStateHighlighted];
    
    [self.pauseButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_pause_btn"] forState:UIControlStateNormal];
    [self.pauseButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_pause_btn_selected"] forState:UIControlStateHighlighted];
    
    [self.nativeShareButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_nativeShare_btn"] forState:UIControlStateNormal];
    
    [self.recordButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_controls_record_off"] forState:UIControlStateNormal];
    [self.recordButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_controls_record_off"] forState:UIControlStateSelected];
    
    [self.subtitlesButton setImage:[APApplicasterResourcesHelper imageNamed:@"player_subtitles_btn"] forState:UIControlStateNormal];
    
    [ZAAppConnector.sharedInstance.chromecastDelegate addButton:self.chromecastButton topOffset:0 width:self.chromecastButton.bounds.size.width buttonKey:@"player_chromecast_icon_color" color:nil useConstrains:YES];
}

#pragma mark - APDefaultPlayerControlsView - public

//+ (ReshetPlayerControlsView *)playerControls
//{
//    return [self viewFromXIBFromBundle:[GAResourceHelper bundleForNibClass:self.class]];
//}

- (void)setSliderForDVRSupport {
   self.seekSlider.isLive = true;
   [super updateControlsForLiveState:NO];
}

-(void)updateControlsForLiveState:(BOOL)isLive
{
   [super updateControlsForLiveState:isLive];
}

- (void)setDuration:(NSTimeInterval)duration{
    [super setDuration:duration];
}

- (void)setCurrentTime:(NSTimeInterval)currentTime{

    if(self.seekSlider.isLive){
        _playbackCurrentTime = currentTime;
        int totalSeconds = (int)currentTime;
        int seconds = totalSeconds % 60;
        int minutes = (totalSeconds / 60) % 60;
        int hours = totalSeconds / 3600;
        
        int totalSecondsDuration = (int)_playbackDuration;
               int secondsDuration = totalSecondsDuration % 60;
               int minutesDuration = (totalSecondsDuration / 60) % 60;
               int hoursDuration = totalSecondsDuration / 3600;
        
        NSString *playbackTime = @"";
           
           if (_playbackCurrentTime > 0.0){
               if (_playbackDuration >= _playbackCurrentTime){
                   playbackTime = [NSString stringWithFormat:@"%@ / %@",
                                   [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds],
                                   [NSString stringWithFormat:@"%02d:%02d:%02d",hoursDuration, minutesDuration, secondsDuration]];
               }
               else{

                   playbackTime = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
               }
           }
           _timeLabel.text = playbackTime;
           [_timeLabel setNeedsLayout];
    }else{
         [super setCurrentTime:currentTime];
    }
}





//+ (UIView<APPlayerControls> *)playerControls
//{
//    return [[NSBundle bundleForClass:self.class] loadNibNamed:@"ReshetPlayerControlsView"
//                                                        owner:self
//                                                      options:nil].firstObject;
//}

@end
