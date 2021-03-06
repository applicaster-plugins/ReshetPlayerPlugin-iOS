//
//  ReshetPlayerViewController.m
//
//  Created by Roi kedarya on 09/12/2019.
//

#import "ReshetPlayerViewController.h"
#import "ReshetPlayerControlsView.h"
#import "ReshetInlinePlayerControlsView.h"
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
@property (nonatomic, strong) UITapGestureRecognizer * singleTapRecognizer;
@property (nonatomic, strong) NSString *artiMediaSiteKey;
@property (nonatomic, assign) APPlayerViewControllerDisplayMode lastPlayerDisplayMode;

#pragma mark - Kantar variables

@property (nonatomic, strong) NSString *kantarMediaStream;
@property (nonatomic, strong) NSString *kantarMediaSiteName;
@property (nonatomic, strong) NSMutableDictionary *kantarAttributes;
@property (nonatomic, strong) KMA_Stream *kantarStream;
@property (nonatomic, strong) KMA_MediaPlayerAdapter *adapter;
@property (strong,nonatomic) AVPlayerViewController* avPlayerViewController;
@property (nonatomic, assign) NSTimeInterval timeIntervalFromServer;
@property (nonatomic, assign) BOOL didSetDeltaInStorage;
@property (nonatomic, assign) NSTimeInterval delta;
@property (nonatomic, strong) NSString *cutTime;
@property (nonatomic, strong) NSString *timeFormat;
@property (nonatomic, strong) id<ZPPlayable> currentlyPlayingItem;
@property (nonatomic, strong) NSString *liveStreamUrl;
@property (nonatomic, strong) NSString *liveStreamSecureUrl;

@end

@implementation ReshetPlayerViewController

@synthesize controls;

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    _kantarMediaSiteName = nil;
    _kantarAttributes = nil;
    _tracker = nil;
    _kantarStream = nil;
    _adapter = nil;
    [self destroyAMSdk];
//    self.controls = nil;
}

#pragma mark - Player Life Cycle Methods
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
        [self addObservers];
        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(onTick:)
                                                    userInfo:nil
                                                     repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
    }
    self.lastPlayerDisplayMode = self.currentPlayerDisplayMode;
    if ([self.currentlyPlayingItem isKindOfClass:[APAtomEntryPlayable class]]) {
        APAtomEntry *atomEntry = ((APAtomEntryPlayable *)self.currentlyPlayingItem).atomEntry;
        BOOL isInFrame = [self isAtomItem:atomEntry InTimeFrame:self.cutTime];
        if (isInFrame) {
            //play live string
            // TO DO
        }
    }
}

- (void)changeDisplayMode:(APPlayerViewControllerDisplayMode)targetDisplayMode {
    [super changeDisplayMode:targetDisplayMode];
    switch (targetDisplayMode) {
        case APPlayerViewControllerDisplayModeInline:
            self.controls = [self reshetInlinePlayerControls];
            [self setControls:self.controls];
            break;
        case APPlayerViewControllerDisplayModeFullScreen:
            if (self.currentPlayerDisplayMode == APPlayerViewControllerDisplayModeInline) {
                self.controls = [self reshetPlayerControls];
                [self setControls:self.controls];
            }
            break;
        default:
            break;
    }

}


- (void)setControls:(UIView<APPlayerControls> *)controls {
    [super setControls:controls];
}

- (UIView<APPlayerControls> *)controls{
    return self.playerController.controls;
}

- (void)viewDidAppear:(BOOL)animated {
    
    [self observeFacebookNotifications];
    
    if (!self.shouldIgnoreViewAppearanceForPlayback) {
        if([_playerController.loadingView respondsToSelector:@selector(loadingStartedWithPlayable:)]){
            [_playerController.loadingView loadingStartedWithPlayable:_playerController.currentItem];
        }
        
    }

    if (self.kantarAttributes) {
        [self startKantarMesurment];
    }
}
- (void)close:(id)sender{
    if(sender){
        [self dismissViewControllerAnimated:true completion:^{
          
        }];
    }else{
        UIImageView *errorImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.playerController.loadingView.width, self.playerController.loadingView.height)];
        errorImage.image = [UIImage imageNamed:@"error_reshet"];
        [self.playerController.loadingView addSubview:errorImage];
        [self.playerController.loadingView bringSubviewToFront:self.playerController.loadingView.cancelButton];
    }
 }


- (AVURLAsset *)assetUrlFromString:(NSString *)urlString {
    AVURLAsset *assetUrl = nil;
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        assetUrl = [AVURLAsset URLAssetWithURL:url options:nil];
    }
    return assetUrl;
}


- (void)play {
    if(isLive && _liveStreamSecureUrl.isNotEmpty){
        APURLPlayable *item  = _currentlyPlayingItem;
        APChannel *channl = ((APChannel*)item);
        [channl setStreamURL:_liveStreamSecureUrl];
        _currentlyPlayingItem = ((APURLPlayable*)channl);
    }
    
    [super play];
    if (self.queuePlayer.player.currentItem.seekableTimeRanges.isNotEmpty) {
        //self.ReshetPlayerControlsView
        CMTimeRange seekableRanges = [self.queuePlayer.player.currentItem.seekableTimeRanges.lastObject CMTimeRangeValue];
        if ([self.controls isKindOfClass:[ReshetPlayerControlsView class]]) {
            [((ReshetPlayerControlsView *)self.controls).seekSlider setInitialValuesWith:seekableRanges];
        }
        NSLog(@"\n\n💜💜💜💜  PLAYING  💜💜💜💜\n\n");
    }
}


- (BOOL)isDVRSupported {

    BOOL retVal = NO;
    NSURL *CurrentlyPlayingUrl = self.currentlyPlayingItem.assetUrl.URL;//[self CurrentlyPlayingUrl];
    retVal = ([[CurrentlyPlayingUrl absoluteString] containsString:@"DVR"]);
    return retVal;
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
        [self.queuePlayer.playerView removeGestureRecognizer:self.singleTapRecognizer];
        
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
        _artiMediaSiteKey = [dictionary objectForKey:@"artimedia_site_key"];
        NSNumber *showAdsOnPaidItems = [dictionary objectForKey:@"show_ads_on_payed"];
        //If showAdsOnPaidItems flag is not set (defualt mode), set it to NO
        if (showAdsOnPaidItems) {
            shouldShowAdsOnPayedItems = [NSNumber numberWithBool:showAdsOnPaidItems];
        } else {
            shouldShowAdsOnPayedItems = NO;
        }
       [self configureKantarAdapter:dictionary];
    }
    _currentlyPlayingItem = items.firstObject;
    _queuePlayer = self.playerController.player;
    _cutTime = [dictionary objectForKey:@"c1_cut_time"];
   
    self.timeFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    self.liveStreamUrl = dictionary[@"live_stream_url"];
    [self setDelta];
    
    return self;
}

- (void)setDelta {
    NSString *deltaString = [ZAAppConnector.sharedInstance.storageDelegate sessionStorageValueFor:@"deltaTimeToServer"
                                                                                        namespace:@"deltaTimeToServer"];
    if (deltaString) {
        _delta = [deltaString doubleValue];
    } else {
        _delta = 0;
    }
}

- (void)configureKantarAdapter:(NSDictionary *)dictionary {
    _kantarMediaSiteName = [dictionary objectForKey:@"kantar_site_key"];
    _kantarMediaStream = [dictionary objectForKey:@"kantar_attribute_stream_value"];
    _avPlayerViewController = [[AVPlayerViewController alloc] init];
    _avPlayerViewController.player = self.playerController.player.player;
    self.adapter = [[KMA_MediaPlayerAdapter alloc] adapter:_avPlayerViewController];
    self.adapter.getMeta.playername = [dictionary objectForKey:@"kantar_player_version_name"];
    self.adapter.getMeta.playerversion = [dictionary objectForKey:@"kantar_player_version"];
    self.kantarAttributes = [[NSMutableDictionary alloc] init];
    [self.kantarAttributes setObject:_kantarMediaSiteName forKey:@"sitename="];
    [self.kantarAttributes setObject:_kantarMediaStream forKey:@"stream"];
}


- (void)replaceSrc:(NSString *)src{
    APURLPlayable *item  = _currentlyPlayingItem;
    if(_currentlyPlayingItem.isLive){
        _liveStreamSecureUrl = src;
    }else{
        [item updateStreamUrl:src];
       _currentlyPlayingItem = item;
    }
}

- (void) startKantarMesurment {
    if (self.kantarAttributes && self.tracker && isLive) {
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
            
            AMInitParams* amInitParams = [[AMInitParams alloc]initWithTargetUIView:_adContainerView initJsonBuilder:[self getInitJsonBuilderParams]];
            
            [_amsdkapi initialize:amInitParams];

        }
        else
        {
            NSLog(@"AMSDK Allocation failed. => Continue without AMSDK.");
        }
    }
}

- (AMInitJsonBuilder *)getInitJsonBuilderParams
{
    
    AMInitJsonBuilder *initJsonBuilder = [[AMInitJsonBuilder alloc] init];
    
    [initJsonBuilder putPlacementSiteKey:self.artiMediaSiteKey];
    [initJsonBuilder putPlacementIsLive:self.currentlyPlayingItem.isLive];
    NSString *url = _currentlyPlayingItem.assetUrl.URL.absoluteString;
    if(url != nil){
        NSString *urlDecode = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
        [initJsonBuilder putContentVideoUrl:urlDecode];
    }
    if ([self.currentlyPlayingItem isKindOfClass:[APAtomEntryPlayable class]]) {
        
        APAtomEntry *atomEntry = ((APAtomEntryPlayable *)self.currentlyPlayingItem).atomEntry;
        [initJsonBuilder putPlacementCategory:atomEntry.identifier];
        [initJsonBuilder putContentId:atomEntry.identifier];
        [initJsonBuilder putContentProgramName:atomEntry.extensions[@"program_name"]];
        [initJsonBuilder putContentType:atomEntry.extensions[@"content_type"]];
        [initJsonBuilder putContentSeason:atomEntry.extensions[@"content_season"]];
        [initJsonBuilder putContentEpisode:atomEntry.extensions[@"content_episode"]];
        [initJsonBuilder putContentGenre:atomEntry.extensions[@"content_genre"]];
        [initJsonBuilder putContentTargetAudience:atomEntry.extensions[@"content_target_audience"]];
       
    }
    
   return initJsonBuilder;
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
            if(player.currentPlaybackTime > 0){
                CMTimeRange seekableRange = [player.player.currentItem.seekableTimeRanges.lastObject CMTimeRangeValue];
                CGFloat seekableDuration = CMTimeGetSeconds(seekableRange.duration);
                if ([self.controls isKindOfClass:[ReshetPlayerControlsView class]]) {
                    [((ReshetPlayerControlsView *)self.controls).seekSlider setInitialValuesWith:seekableRange];
                    [self.controls setDuration:seekableDuration];
                }
            }
            if ([self.controls respondsToSelector:@selector(updateControlsForLiveState:)]){
                if ([self isDVRSupported]) {
                    if ([self.controls isKindOfClass:[ReshetPlayerControlsView class]]) {
                        [((ReshetPlayerControlsView *)self.controls) setSliderForDVRSupport];
                    }
                } else {
                    [self.controls updateControlsForLiveState:YES];
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

//in order to reduce the server calls to get the server time we calculate the server time using the delta
- (NSDate *)calculateServerTimeWithDelta:(NSTimeInterval)delta {
    NSDate *currentServerTime = [[NSDate date] dateByAddingTimeInterval:delta];
    return currentServerTime;
}


 /*
  time frame is the number of hours for the c+1 time frame as defined by kantar.
  if we have an atomEntry - check it's starting time to see if it is in the time frame of c+1
 */
- (BOOL)isAtomItem:(APAtomEntry *)atomEntry InTimeFrame:(NSString *)cutTimeString {
    BOOL retVal = NO;
    id broadcastTimeInMiliSec = ([atomEntry.extensions objectForKey:@"video_start_time"]);
    NSString *windowTimeFrameString = self.artiParams[@"c1_window_length_time"];
    if ([broadcastTimeInMiliSec isKindOfClass:[NSNumber class]] && windowTimeFrameString.isNotEmptyOrWhiteSpaces) {
        double broadcastTimeSec = ((NSNumber *)broadcastTimeInMiliSec).doubleValue / 1000;
        double windowTimeFrameSec = [windowTimeFrameString doubleValue] / 1000;
        NSTimeInterval currentDeviceTime = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval serverTime = currentDeviceTime + self.delta;
        BOOL isInTimeFrameWindow = serverTime - broadcastTimeSec < windowTimeFrameSec;
        if (isInTimeFrameWindow) {
            NSDate *now = [NSDate dateWithTimeIntervalSince1970:serverTime];
            double daySeconds = 86400;
            NSDate *videoStartDate = [NSDate dateWithTimeIntervalSince1970:broadcastTimeSec];
            NSRange range = [cutTimeString rangeOfString:@":"];
            NSString *cutTimeHour = [cutTimeString substringToIndex:range.location];
            NSString *cutTimeMinutes = [cutTimeString substringFromIndex:(range.location + 1)];
            NSCalendar *calender = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
            calender.timeZone = timeZone;
            NSDateComponents *timeComponents = [calender components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:videoStartDate];
            
            [timeComponents setHour:cutTimeHour.intValue];
            [timeComponents setMinute:cutTimeMinutes.intValue];
            NSDate *cutTime = [calender dateFromComponents:timeComponents];
            if ([cutTime timeIntervalSinceDate:videoStartDate] > 0) {
                [cutTime dateByAddingTimeInterval:daySeconds];
            } else {
                [cutTime dateByAddingTimeInterval:(2*daySeconds)];
            }
            BOOL isC1 = ([cutTime timeIntervalSinceDate:now] > 0);
            retVal = isC1;
        }
    }
    return retVal;
}

//- (void)reloadUrlForDVRSupport:(UISlider *)slider WithDuration:(CGFloat)duration {
//    // reloads the url to get the latest live stream
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.queuePlayer.player.currentItem.asset];
//    [self.queuePlayer.player replaceCurrentItemWithPlayerItem: playerItem];
//
//    //set slider's new min and max values
//    [slider setMaximumValue: duration];
//    [slider setMinimumValue:0.0];
//    [slider setValue:duration];
//}
//
//- (void)controlsSliderChangeEnded:(id)sender {
//    [super.self.queuePlayer controlsSliderChangeEnded:sender];
//    if ([self isDVRSupported]) { //check for DVR support
//        UISlider *slider = (UISlider *)sender;
//        CMTimeRange seekableRange = [self.queuePlayer.player.currentItem.seekableTimeRanges.lastObject CMTimeRangeValue];
//        CGFloat seekableDuration = CMTimeGetSeconds(seekableRange.duration);
//        BOOL isSliderReachLivePoint = ([slider maximumValue] == [slider value]);
//        if (isSliderReachLivePoint) {
//            [self reloadUrlForDVRSupport:slider WithDuration:seekableDuration];
//        }
//    }
//}

- (UIView<APPlayerControls> *)reshetPlayerControls
{
    return [[NSBundle bundleForClass:self.class] loadNibNamed:@"ReshetPlayerControlsView"
                                                        owner:self
                                                      options:nil].firstObject;
}

- (UIView<APPlayerControls> *)reshetInlinePlayerControls
{
    return [[NSBundle bundleForClass:self.class] loadNibNamed:@"ReshetInlinePlayerControlsView"
                                                        owner:self
                                                      options:nil].firstObject;
}

#pragma mark - Timer hack
-(void)onTick:(NSTimer*)timer
{
    timer = nil;
    [self play];
}

@end



