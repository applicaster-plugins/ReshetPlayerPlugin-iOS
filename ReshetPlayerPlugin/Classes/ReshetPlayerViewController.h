//
//  ReshetPlayer.h
//
@import ApplicasterSDK;

#import <UIKit/UIKit.h>

#define UPDATE_TIME_DELAY           1.0
#define TEST_SITE_KEY               @"bayontv"

@interface ReshetPlayerViewController : APPlayerViewController

- (instancetype)initWithPlayableItems:(NSArray*)items withArtiMediaParams:(NSDictionary *)dictionary;

@end
