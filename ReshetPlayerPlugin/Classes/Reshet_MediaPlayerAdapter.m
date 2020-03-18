////
////  Reshet_MediaPlayerAdapter.m
////  KMA_SpringStreams
////
////  Created by Roi kedarya on 09/12/2019.
////  Copyright 2011 spring GmbH & Co. KG. All rights reserved.
////
//
//
//
//#import "KMA_SpringStreams.h"
//#import "ReshetPlayerViewController.h"
//
//@interface KMA_MediaPlayerAdapter()
//
//@property (nonatomic, strong) AVPlayerViewController *playerVC;
//@property (nonatomic, strong) KMA_Player_Meta *meta;
//
//@end
// 
//@implementation KMA_MediaPlayerAdapter
//
//- (KMA_MediaPlayerAdapter *)adapter:(AVPlayerViewController *)player{
//    _playerVC = player;
//    return [super init];
//}
//
//
//#pragma KMA_StreamAdapter Protocol
//
//-(KMA_Player_Meta* )getMeta {
//    _meta = [[KMA_Player_Meta alloc] init];
//    _meta.screenwidth = [self getWidth];
//    _meta.screenheight = [self getHeight];
//    return _meta;
//}
//
//- (int) getPosition {
//    int livePosition = CMTimeGetSeconds(_playerVC.player.currentItem.currentTime);
//    if(livePosition < 0) livePosition = 0;
//    return livePosition;
//}
//
//- (int) getDuration {
//    return CMTimeGetSeconds(_playerVC.player.currentItem.duration);
//}
//
//
//- (int) getWidth {
//    return _playerVC.view.bounds.size.width;
//}
//
//- (int) getHeight {
//    return _playerVC.view.bounds.size.height;
//}
//
//-(BOOL) isCastingEnabled{
//    return NO;
//}
//
//- (void)dealloc
//{
//    _playerVC = nil;
//    _meta = nil;
//}
//
//
//
//
//@end
//
//@implementation KMA_Player_Meta
//
///**
// * Returns the player name
// *
// * @return the string "MediaPlayer"
// */
//@synthesize playername;
// 
///**
// * Returns the player version.
// * The itselfs has no version so the system version is delivered.
// *
// * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIDevice_Class/Reference/UIDevice.html
// *
// * @return The version my calling [UIDevice currentDevice].systemVersion
// */
//@synthesize playerversion;
// 
///**
// * Returns the screen width my calling the method
// * [[UIScreen mainScreen] bounds].screenRect.size.width
// *
// * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIScreen_Class/Reference/UIScreen.html
// *
// * @return the width
// */
//@synthesize screenwidth;
// 
///**
// * Returns the screen width my calling the method
// * [[UIScreen mainScreen] bounds].screenRect.size.height
// *
// * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIScreen_Class/Reference/UIScreen.html
// *
// * @return the height
// */
//@synthesize screenheight;
// 
//
//
//@end
