//
//  ReshetPlayerControlsView.h
//  ReshetPlayerPlugin
//
//  Created by Roi Kedarya on 03/12/2019.
//

#import <ApplicasterSDK/ApplicasterSDK.h>
#import "ReshetSlider.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReshetPlayerControlsView : APPlayerControlsView <APPlayerControls>

//@property (nonatomic, readonly, weak) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet ReshetSlider *seekSlider;
//@property (nonatomic, readonly, weak) IBOutlet UIButton *stopButton;
//@property (nonatomic, weak) IBOutlet MPVolumeView *volumeView;
@property (nonatomic,readonly, weak) IBOutlet UIButton *nativeShareButton;
//@property (nonatomic, readonly, weak) IBOutlet UIButton *subtitlesButton;
@property (weak, nonatomic) IBOutlet UIView *chromecastButton;

//@property (weak, nonatomic) IBOutlet UIButton *playButton;
- (void)setSliderForDVRSupport;

@end

NS_ASSUME_NONNULL_END
