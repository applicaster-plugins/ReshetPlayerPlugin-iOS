//
//  ReshetSlider.h
//  ReshetPlayerPlugin
//
//  Created by Roi Kedarya on 05/12/2019.
//

#import <ApplicasterSDK/ApplicasterSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReshetSlider : APSlider

@property (nonatomic, assign) BOOL isLive;
@property (nonatomic, assign) float timeframe;

- (void)setMaximumValue:(float)maximumValue;
- (void)setValue:(float)value;
- (void)setMinimumValue:(float)minimumValue;
- (void)setInitialValuesWith:(CMTimeRange)timeRange;
@end


NS_ASSUME_NONNULL_END
