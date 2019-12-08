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
    if ([self.delegate respondsToSelector:@selector(setSliderForDVRSupport)]) {
        [self.delegate setSliderForDVRSupport];
    }
//    } else {
//        [super setMaximumValue:maximumValue];
//    }
}

@end
