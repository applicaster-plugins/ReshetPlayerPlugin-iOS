//
//  ReshetInlinePlayerControlsView.h
//  Zapp-App
//
//  Created by Roi kedarya on 09/12/2019.
//  Copyright © 2019 Applicaster LTD. All rights reserved.
//

@import ApplicasterSDK;
@import MediaPlayer;
#import <ApplicasterSDK/APPlayerControls.h>
#import <ApplicasterSDK/APPlayerControlsView.h>
#import <ApplicasterSDK/APUnhittableView.h>
#import <ApplicasterSDK/APGradientView.h>

@interface ReshetInlinePlayerControlsView : APPlayerControlsView <APPlayerControls>
@property (nonatomic, weak) IBOutlet MPVolumeView *volumeView;
@property (weak, nonatomic) IBOutlet APUnhittableView *playerControlsContainer;
@property (weak, nonatomic) IBOutlet APGradientView *topGradientView;
@property (weak, nonatomic) IBOutlet APGradientView *bottomGradientView;
@property (nonatomic,readonly, weak) IBOutlet UIButton *playButton;
@property (nonatomic,readonly, weak) IBOutlet UIButton *pauseButton;
@property (nonatomic,readonly, weak) IBOutlet APSlider *seekSlider;
@property (nonatomic,readonly, weak) IBOutlet UIButton *expandButton;
@property (nonatomic,readonly, weak) IBOutlet UIButton *nativeShareButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

+ (UIView<APPlayerControls> *)playerControls;

@end
