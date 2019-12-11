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

@synthesize delegate;

- (void)awakeFromNib {
    [super awakeFromNib];
    //[super setMaximumValue: 28800];
}


- (void)setMaximumValue:(float)maximumValue {
    NSLog(@"\n\n💙💙💙💙  slider maximum value is in %f  💙💙💙💙\n\n", maximumValue);
    if ([self.delegate respondsToSelector:@selector(setSliderForDVRSupport)]) {
        [self.delegate setSliderForDVRSupport];
    }
}

- (void)setValue:(float)value {
    NSLog(@"\n\n💛💛💛💛  slider time is %f  💛💛💛💛\n\n", value);
    [super setValue:value];
}

- (void)setMinimumValue:(float)minimumValue {
    NSLog(@"\n\n💜💜💜💜  slider minimum value is in %f  💜💜💜💜\n\n", minimumValue);
    [super setMinimumValue:minimumValue];
}

- (void)setInitialValuesWith:(CMTimeRange)timeRange {
    CGFloat maximumValue = CMTimeGetSeconds(timeRange.duration);
    [super setMaximumValue:maximumValue];
    CGFloat minimumValue = CMTimeGetSeconds(timeRange.start);
    [super setMinimumValue:minimumValue];
    
}

- (void)dealloc
{
    delegate = nil;
}

@end
