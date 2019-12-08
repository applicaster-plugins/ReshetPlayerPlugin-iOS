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

@property (weak, nonatomic) IBOutlet ReshetSlider *seekSlider;
@property (nonatomic,readonly, weak) IBOutlet UIButton *nativeShareButton;
@property (nonatomic, weak) IBOutlet MPVolumeView *volumeView;
@property (weak, nonatomic) IBOutlet UIView *chromecastButton;
- (void)setSliderForDVRSupport;

@end

NS_ASSUME_NONNULL_END
