//
//  ArtiPlayer.m
//  ArtiMediaPlayer
//
//  Created by Avi Levin on 05/07/2018.
//

#import "ReshetPlayerViewController.h"
#import "ArtiSDK/AMSDK.h"
#import "KMA_SpringStreams.h"

@import Foundation;
@import ZappPlugins;

@interface ReshetPlayerViewController () <AMEventDelegate, ZPAppLoadingHookProtocol> {
    #pragma mark - Player state variables
    BOOL adPlayInProgress;
    BOOL isLive;
    BOOL adSessionAlive;
    BOOL contentInProgress;
    BOOL isToUpdateContentUIThread;
    BOOL isInitialized;
    BOOL isMeVisible;
    BOOL shouldShowAdsOnPayedItems;
}

#pragma mark - Player private variables
@property (nonatomic, strong) id <AMSDKAPI> amsdkapi;
@property (nonatomic, strong) NSThread* updateContentUIThread;
@property (nonatomic, strong) UIView* adContainerView;
@property (nonatomic, strong) NSDictionary* artiParams;
@property (nonatomic, strong) UITapGestureRecognizer * singleTapRecognizer;
@property (nonatomic, strong) NSString *artiMediaSiteKey;
@property (nonatomic, assign) APPlayerViewControllerDisplayMode lastPlayerDisplayMode;

#pragma mark - Kantar variables

@property (nonatomic, strong) NSString *KantarMediaSiteName;
@property (nonatomic, strong) NSMutableDictionary *kantarAttributes;
@property (nonatomic, strong) KMA_SpringStreams *tracker;
@property (nonatomic, strong) KMA_Stream *kantarStream;
@property (nonatomic, strong) Reshet_MediaPlayerAdapter *adapter;
@property (nonatomic, assign) NSTimeInterval timeIntervalFromServer;
@property (nonatomic, assign) BOOL didSetDeltaInStorage;
@property (nonatomic, assign) NSTimeInterval Delta;

@end

@implementation ReshetPlayerViewController

#pragma mark - Player Life Cycle Methods
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self requestServerForCurrentTime];
    
    if([self shouldDisplayAds]) {
        if ([self ignoreAdsOnChangeMode]) {
            //If the player was paused due to an ad and the view got desroid it will start on paused
            if(self.currentPlayerDisplayMode == APPlayerViewControllerDisplayModeInline && self.playerController.player.playbackState == APMoviePlaybackStatePaused) {
                [self play];
            }
        }
        else {
            //State managemnet
            isLive = self.playerController.currentItem.isLive;
            isMeVisible = YES;
            
            //Should help in a case when a user tap on the home button when an ad is playing.
            [self addObservers];
            
            //Add an ad contrainer view above all other view (after super.viewWillAppear)
            [self.view addSubview:self.adContainerView];
            [self.adContainerView matchParent];
            self.adContainerView.hidden = YES;
            
            //If the player was paused due to an ad and the view got desroid it will start on paused
            if(self.currentPlayerDisplayMode == APPlayerViewControllerDisplayModeInline && self.playerController.player.playbackState == APMoviePlaybackStatePaused) {
                [self play];
            }
            
            //If the player starts muted don't show ads, we'll start to show ads once the player is unmuted
            if(self.playerController.player.muted) {
                UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                      action:nil];
                doubleTapRecognizer.numberOfTapsRequired = 2;
                
                _singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(singleTapped:)];
                _singleTapRecognizer.numberOfTapsRequired = 1;
                [_singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
                
                [self.playerController.player.playerView addGestureRecognizer: self.singleTapRecognizer];
                
            } else {
                [self initSDKwithParams:_artiParams];
            }
        }
    } else {
        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(onTick:)
                                                    userInfo:nil
                                                     repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
    }
    self.lastPlayerDisplayMode = self.currentPlayerDisplayMode;
}

- (void)viewDidAppear:(BOOL)animated {
    
    [self observeFacebookNotifications];
    
    if (!self.shouldIgnoreViewAppearanceForPlayback) {
        if([_playerController.loadingView respondsToSelector:@selector(loadingStartedWithPlayable:)]){
            [_playerController.loadingView loadingStartedWithPlayable:_playerController.currentItem];
        }
        
    }
        APSlider *slider = self.playerController.controls.seekSlider;
        slider.hidden = ![self isDVRSupported];
    if (slider.hidden == NO) {
        UIImage *thumbImage = [APApplicasterResourcesHelper imageNamed:@"player_controls_seek_button"];
        [slider setThumbImage:thumbImage forState:UIControlStateNormal];
    }
    if (self.kantarAttributes) {
        [self startKantarMesurment];
    }
//    if (self.adapter) {
//        [self.adapter getPosition];
//    }
//    if ([self.playerController.player.defaultControls isKindOfClass:[APPlayerControlsView class]]) {
//        APPlayerControlsView * controls = (APPlayerControlsView *)self.playerController.player.defaultControls;
//        [controls customizeSeekSliderView:slider];
//    }
}

- (BOOL)isDVRSupported {
    return [self.playerController.player isDVRSupported];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    if([self shouldDisplayAds] && ![self ignoreAdsOnChangeMode]) {
        //Update states
        adPlayInProgress = NO;
        contentInProgress = NO;
        
        //Remove objects
        [self stopUpdateContentUIThread];
        [self removeObservers];
        [self.adContainerView removeFromSuperview];
        [self.playerController.player.playerView removeGestureRecognizer:self.singleTapRecognizer];
        
        [self destroyAMSdk];
        _adContainerView = nil;
    }
    [self stopObservingFacebookNotifications];
    [super viewWillDisappear:animated];
    
    [self stopKantarMesurment];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public Methods
- (instancetype)initWithPlayableItems:(NSArray*)items withArtiMediaParams:(NSDictionary *)dictionary {
    if (self = [super initWithPlayableItems:items])
    {
        _artiParams = dictionary;
        _artiMediaSiteKey = [dictionary objectForKey:@"siteKey"];
        
        _KantarMediaSiteName = [dictionary objectForKey:@"site_name"];
        
        NSNumber *showAdsOnPaidItems = [dictionary objectForKey:@"show_ads_on_payed"];
        //If showAdsOnPaidItems flag is not set (defualt mode), set it to NO
        if (showAdsOnPaidItems) {
            shouldShowAdsOnPayedItems = [NSNumber numberWithBool:showAdsOnPaidItems];
        } else {
            shouldShowAdsOnPayedItems = NO;
        }
        [self ConfigureKantarAdapter];
    }
    NSString *deltaString = [ZAAppConnector.sharedInstance.storageDelegate sessionStorageValueFor:@"deltaTimeToServer"
                                                                                        namespace:@"deltaTimeToServer"];
    if (deltaString) {
        self.Delta = [deltaString doubleValue];
    }
    return self;
}

- (void)ConfigureKantarAdapter {
    NSString *appDisplayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    //self.tracker = [KMA_SpringStreams getInstance:_KantarMediaSiteName a:appDisplayName];
    //self.adapter = [[Reshet_MediaPlayerAdapter alloc] adapter:self];
    self.kantarAttributes = [[NSMutableDictionary alloc] init];
//    NSString *width = [NSString stringWithFormat:@"%d",[self.adapter getWidth]];
//    NSString *height = [NSString stringWithFormat:@"%d",[self.adapter  getHeight]];
//    if ([width isNotEmpty]) {
//        [self.kantarAttributes setObject:width forKey:@"sx"];
//    }
//    if ([height isNotEmpty]) {
//        [self.kantarAttributes setObject:height forKey:@"sy"];
//    }

}

- (void) startKantarMesurment {
    if (self.kantarAttributes && isLive) {
        self.kantarStream = [self.tracker track:self.adapter atts:self.kantarAttributes];
    }
}

- (void)stopKantarMesurment {
    if (self.kantarStream && [self isDVRSupported]) {
        [self.kantarStream stop];
    }
}

#pragma mark - Private Methods

- (BOOL)shouldDisplayAds {
    return self.artiMediaSiteKey.isNotEmpty && ([self.playerController.currentItem isFree] || shouldShowAdsOnPayedItems);
}

- (BOOL)ignoreAdsOnChangeMode {
    return ((self.lastPlayerDisplayMode == APPlayerViewControllerDisplayModeInline && self.currentPlayerDisplayMode == APPlayerViewControllerDisplayModeFullScreen) || (self.lastPlayerDisplayMode == APPlayerViewControllerDisplayModeFullScreen && self.currentPlayerDisplayMode == APPlayerViewControllerDisplayModeInline));
}

- (UIView*)adContainerView
{
    if (!_adContainerView) {
        _adContainerView = [[UIView alloc] init];
    }
    return _adContainerView;
}

#pragma mark - ArtiSDK Logic
- (void)initSDKwithParams: (NSDictionary *)artiParamsDictionary {

    //init artimedia only if chromecast is not synced & artimedia siteKey was configured
    if(![[ZAAppConnector sharedInstance] chromecastDelegate].isSynced)  {
        _amsdkapi = [AMSDK getVideoAdvAPI];
        if( _amsdkapi )
        {
            [_amsdkapi registerEvent:EVT_INIT_COMPLETE eventDelegate:self];
            [_amsdkapi registerEvent:EVT_PAUSE_REQUEST eventDelegate:self];
            [_amsdkapi registerEvent:EVT_RESUME_REQUEST eventDelegate:self];
            [_amsdkapi registerEvent:EVT_LINEAR_AD_START eventDelegate:self];
            [_amsdkapi registerEvent:EVT_LINEAR_AD_PAUSE eventDelegate:self];
            [_amsdkapi registerEvent:EVT_LINEAR_AD_RESUME eventDelegate:self];
            [_amsdkapi registerEvent:EVT_LINEAR_AD_STOP eventDelegate:self];
            [_amsdkapi registerEvent:EVT_AD_MISSED eventDelegate:self];
            [_amsdkapi registerEvent:EVT_AD_SHOW eventDelegate:self];
            [_amsdkapi registerEvent:EVT_AD_HIDE eventDelegate:self];
            [_amsdkapi registerEvent:EVT_SESSION_END eventDelegate:self];
            [_amsdkapi registerEvent:EVT_AD_CLICK eventDelegate:self];
            [_amsdkapi registerEvent:EVT_AD_SCREEN_TOUCH_DOWN eventDelegate:self];
            [_amsdkapi registerEvent:EVT_AD_SCREEN_TOUCH_UP eventDelegate:self];
            
            NSDictionary *artiWithStreamParamsDictionary = [self addVideoParametersToArtiParamsDictionary:artiParamsDictionary];
            AMInitParams* amInitParams = [[AMInitParams alloc] initWithTargetUIView: self.adContainerView
                                                                             params:artiWithStreamParamsDictionary];
            
            [_amsdkapi initialize:amInitParams];

        }
        else
        {
            NSLog(@"AMSDK Allocation failed. => Continue without AMSDK.");
        }
    }
}

- (NSDictionary *)addVideoParametersToArtiParamsDictionary:(NSDictionary *) artiParamsDictionary{
    NSMutableDictionary *retValue;
    
    if(artiParamsDictionary) {
        retValue = [artiParamsDictionary mutableCopy];
        
        [retValue setValue:[NSNumber numberWithBool:isLive] forKey:@"isLive"];
    }
    
    return retValue;
}

- (void)onAMSDKEvent:(AMEventType)event eventData:(nullable NSObject*)data
{
    NSLog(@"PUBLISHER onAMSDKEvent: %@", EventTypeToString(event));
    
    switch (event)
    {
        case EVT_INIT_COMPLETE:
            [self onInitComplete:data];
            break;
        case EVT_AD_SHOW:
            [self setAdVolume];
            break;
        case EVT_AD_HIDE:
            break;
        case EVT_PAUSE_REQUEST:
            [self pauseContent];
            if(_amsdkapi)
                [_amsdkapi updateVideoState:VIDEO_STATE_PAUSE];
            break;
        case EVT_RESUME_REQUEST:
            [self resumeContent];
            if(_amsdkapi)
                [_amsdkapi updateVideoState:VIDEO_STATE_RESUME];
            break;
        case EVT_LINEAR_AD_START:
            self.adContainerView.hidden = NO;
            break;
        case EVT_LINEAR_AD_PAUSE:
            break;
        case EVT_LINEAR_AD_RESUME:
            break;
        case EVT_LINEAR_AD_STOP:
            self.adContainerView.hidden = YES;
            [self play];
            break;
        case EVT_AD_MISSED:
            [self resumeContent];
            break;
        case EVT_SESSION_END:
            [self resumeContent];
            [self destroyAMSdk];
            break;
        case EVT_AD_CLICK:
            break;
        case EVT_AD_SCREEN_TOUCH_DOWN:
            //            Do something if needed...
            break;
        case EVT_AD_SCREEN_TOUCH_UP:
            //            Do something if needed...
            break;
        case EVT_ERROR:
            //            Do nothing...
            break;
    }
}

- (void)onResumePressed
{
    if(adPlayInProgress) {
        if(_amsdkapi)
            [_amsdkapi resumeAd];
    }
    [self startKantarMesurment];
}

- (void)onPausePressed
{
    if(adPlayInProgress) {
        if(_amsdkapi)
            [_amsdkapi pauseAd];
    } else {
        [self pause];
        [self stopKantarMesurment];
    }
}

- (void)onInitComplete:(NSObject*)data
{
    adSessionAlive = [((NSNumber*) data) boolValue];
    contentInProgress = YES;
    
    [self resumeContent];

    
    [self startUpdateContentUIThread];
    
    if ( adSessionAlive ) {
        if(_amsdkapi)
            [_amsdkapi updateVideoState:VIDEO_STATE_PLAY];
    }
    else {
        [self destroyAMSdk];
    }
    isInitialized = YES;
}

- (void)setAdVolume{
    if(_amsdkapi) {
        [_amsdkapi setAdVolume:self.playerController.player.player.volume];
    }
}

- (void)startUpdateContentUIThread
{
    if(!_updateContentUIThread)
    {
        isToUpdateContentUIThread = YES;
        _updateContentUIThread = [[NSThread alloc] initWithTarget:self
                                                         selector:@selector(updateContentUI)
                                                           object:nil];
        [_updateContentUIThread start];
    }
}

- (void)stopUpdateContentUIThread
{
    isToUpdateContentUIThread = NO;
    if(_updateContentUIThread)
        [_updateContentUIThread cancel];
    _updateContentUIThread = nil;
}

- (void)updateContentUI
{
    while (isToUpdateContentUIThread)
    {
        if (contentInProgress)
        {
            if(_amsdkapi)
            {
                [_amsdkapi updateVideoTime:self.playerController.currentPlaybackTime];
                
                //In case the VC didn't get released yet when a Chromecast connection was established
                if([[ZAAppConnector sharedInstance] chromecastDelegate].isSynced) {
                    [self destroyAMSdk];
                    [self closeWithCommercials:NO animated:YES shouldDismiss:NO completionHandler:nil];
                }
            }
            sleep(UPDATE_TIME_DELAY);
        }
    }
}

- (void)destroyAMSdk
{
    [self stopUpdateContentUIThread];
    
    if( _amsdkapi ) {
        [_amsdkapi destroy];
    }
    _amsdkapi = nil;
    
}

- (void)resumeContent
{
    adPlayInProgress = NO;
    contentInProgress = YES;
    
    [self play];
}

- (void)pauseContent
{
    adPlayInProgress = YES;
    contentInProgress = NO;
    
    [self pause];
}

#pragma mark - Player Tap Recognizer
- (void)singleTapped:(UIGestureRecognizer *)gestureRecognizer {
    //Remove the GestureRecognizer
    [self.playerController.player.playerView removeGestureRecognizer:self.singleTapRecognizer];
    self.singleTapRecognizer = nil;
    
    //Hide if visible and show if not
    if ([self.controls isVisible] == YES){
        [self.controls hide:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:APPlayerHideControNotification object:self userInfo:nil];
    }
    else {
        //Controls should be displayed
        [self.playerController.player autoShowHideControls];
    }
    
    if (self.playerController.player.muted) {
        self.playerController.player.muted = NO;
        self.playerController.player.mutedUntilTouched = NO;
        [self initSDKwithParams:_artiParams];
    }
}

#pragma mark - Observers logic
- (void)addObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerLoadStateChanged:)
                                                 name:APMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPause)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResume)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chromecastSessionDidStart:)
                                                 name:@"ChromecastSessionDidStart"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDialogDidOpenNotification:)
                                                 name:APFacebookFeedDidOpenNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDialogDidCloseNotification:)
                                                 name:APFacebookFeedDidCloseNotification
                                               object:nil];
}

- (void)removeObservers {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:APMoviePlayerLoadStateDidChangeNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"ChromecastSessionDidStart"
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:APFacebookFeedDidOpenNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:APFacebookFeedDidCloseNotification
                                                  object:nil];
}

// Like in Android
- (void)onPause
{
    isMeVisible = NO;
    [self onPausePressed];
}

// Like in Android
- (void)onResume
{
    isMeVisible = YES;
    
    [self onResumePressed];
}

// Chromecast Observer
- (void)chromecastSessionDidStart:(NSNotification*)notification {
    [self destroyAMSdk];
    self.view.backgroundColor = UIColor.blackColor;
}

- (void)playerLoadStateChanged:(NSNotification*)notification{
    if ([notification.object isKindOfClass:[APPlayer class]]) {
        APPlayer *player = notification.object;
        if (player.durationType == APPlayerContentDurationTypeIndefinite) {
            if ([self.controls respondsToSelector:@selector(updateControlsForLiveState:)]){
                [self.controls updateControlsForLiveState:YES];
                if ([self isDVRSupported]) {
//                    remove this
//                    if (self.adapter) {
//                        [self.adapter getPosition];
//                    }
                    APSlider *slider = self.playerController.controls.seekSlider;
                    [slider setContinuous:NO];
                    slider.hidden = NO;
                }
            }
        }
        else {
            if ([self.controls respondsToSelector:@selector(updateControlsForLiveState:)]){
                [self.controls updateControlsForLiveState:NO];
            }
        }
    }
}

#pragma mark - Facebook logic
- (void)facebookDialogDidOpenNotification:(NSNotification *)notification
{
    // Close the interruption view in case it opens on back from background during SSO
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive)
    {
        // This trick allows the call to happen on the next run loop, after the application state changes from inactive to active.
        // Without this the interruption view would be added after this call.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.playerController.interruptionView removeFromSuperview];
        });
    }
    
    [self pause];
}

- (void)facebookDialogDidCloseNotification:(NSNotification *)notification {
    [self play];
}

- (void)observeFacebookNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDialogDidOpenNotification:)
                                                 name:APFacebookFeedDidOpenNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDialogDidCloseNotification:)
                                                 name:APFacebookFeedDidCloseNotification
                                               object:nil];
}

- (void)stopObservingFacebookNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:APFacebookFeedDidOpenNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:APFacebookFeedDidCloseNotification
                                                  object:nil];
}

#pragma mark -

- (void)executeOnApplicationReadyWithDisplayViewController:(UIViewController *)displayViewController completion:(void (^)(void))completion {
    [self requestServerForCurrentTime];
    completion();
}

- (void)requestServerForCurrentTime {
    NSString *urlString = @"https://13tv.co.il/timestamp.php";
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    //make request to get current serverTime
    [APNetworkManager requestDataObjectForRequest:urlRequest completion:^(BOOL successStatus, NSData * _Nullable responseObject, NSError * _Nullable error, NSInteger statusCode) {
        NSDictionary *options = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)};
        NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithData:responseObject
                                                                                        options:options
                                                                             documentAttributes:nil
                                                                                          error:nil];
        if ([dateString isNotEmpty]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            [self setDeltaFromDateString:dateString.string andFormatter:dateFormatter];
        }
    }];
}

- (void)setDeltaFromDateString:(NSString *)serverDateString
                  andFormatter:(NSDateFormatter *)dateFormatter {
    //NSString *nowDateString = [dateFormatter stringFromDate:[NSDate date]];
    //[self convertToDateWithString:nowDateString andFormatter:dateFormatter];
    NSDate *now = [NSDate date];
    NSDate *serverTime = [self convertToDateWithString:serverDateString andFormatter:dateFormatter];
    NSTimeInterval timeIntervalFromServer = [now timeIntervalSinceDate:serverTime];
    if (timeIntervalFromServer) {
        NSString *intervalString = [NSString stringWithFormat:@"%f", timeIntervalFromServer];
        self.didSetDeltaInStorage = [ZAAppConnector.sharedInstance.storageDelegate sessionStorageSetValueFor:@"deltaTimeToServer" value:intervalString namespace:@"deltaTimeToServer"];
    }
}

- (NSDate *)convertToDateWithString:(NSString *)dateString andFormatter:(NSDateFormatter *)dateFormatter{
    NSDate *dateFromString = [dateFormatter dateFromString:dateString];
    return dateFromString;
}

//in order to reduce the server calls to get the server time we calculate the server time using the delta
- (NSDate *)calculateServerTimeWithDelta:(NSTimeInterval)delta {
    NSDate *currentServerTime = [[NSDate date] dateByAddingTimeInterval:delta];
    return currentServerTime;
}

//time frame is the number of hours for the c+1 time frame as defined by kantar
- (BOOL)isInTimeFrame:(NSString *)timeFrame {
    BOOL retVal = NO;
    return retVal;
}

#pragma mark - Timer hack
-(void)onTick:(NSTimer*)timer
{
    timer = nil;
    [self play];
}
@end