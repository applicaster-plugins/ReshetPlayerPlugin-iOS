//
//  ReshetPlayerViewController.h
//
@import ApplicasterSDK;

#import <UIKit/UIKit.h>
#define UPDATE_TIME_DELAY           1.0
#define TEST_SITE_KEY               @"bayontv"

//@interface APPlayerViewController : UIViewController {
//    APPlayerController          *_playerController;
//}
//@end

@interface ReshetPlayerViewController : APPlayerViewController

@property (nonatomic, strong) NSDictionary* artiParams;

- (instancetype)initWithPlayableItems:(NSArray*)items withArtiMediaParams:(NSDictionary *)dictionary;

- (void)setControls:(UIView<APPlayerControls> *)controls;

//- (UIView<APPlayerControls> *)reshetPlayerControls;
//
//- (UIView<APPlayerControls> *)reshetInlinePlayerControls;

@end
