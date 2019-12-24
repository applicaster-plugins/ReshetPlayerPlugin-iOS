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
@property (nonatomic, strong) APQueuePlayer *queuePlayer;
//@property (nonatomic, strong) UIView<APPlayerControls> *controls;

- (instancetype)initWithPlayableItems:(NSArray*)items withArtiMediaParams:(NSDictionary *)dictionary;

- (void)setControls:(UIView<APPlayerControls> *)controls;

- (BOOL)isDVRSupported;

-(void)replaceSrc:(NSString *)src;

- (UIView<APPlayerControls> *)reshetPlayerControls;

- (UIView<APPlayerControls> *)reshetInlinePlayerControls;

@end
