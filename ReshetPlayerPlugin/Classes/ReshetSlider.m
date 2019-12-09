//
//  ReshetSlider.m
//  ReshetPlayerPlugin
//
//  Created by Roi Kedarya on 05/12/2019.
//

#import "ReshetSlider.h"

@interface ReshetSlider()

@property (nonatomic, strong) id<APPlayerControls> delegate;

@end

@implementation ReshetSlider

- (void)awakeFromNib {
    [super awakeFromNib];
}


- (void)setMaximumValue:(float)maximumValue {
//    if (self.isLive) {
     APLoggerDebug(@"slider maximum value is in %f", maximumValue);
    if ([self.delegate respondsToSelector:@selector(setSliderForDVRSupport)]) {
        [self.delegate setSliderForDVRSupport];
    }
//    } else {
//        [super setMaximumValue:maximumValue];
//    }
}

- (void)setValue:(float)value {
    APLoggerDebug(@"slider time is in %f", value);
    [super setValue:value];
}

- (void)setMinimumValue:(float)minimumValue {
    APLoggerDebug(@"slider minimum value is in %f", minimumValue);
    [super setMinimumValue:minimumValue];
}

@end
