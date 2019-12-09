//
//  Reshet_MediaPlayerAdapter.m
//  KMA_SpringStreams
//
//  Created by Roi kedarya on 09/12/2019.
//  Copyright 2011 spring GmbH & Co. KG. All rights reserved.
//



#import "KMA_SpringStreams.h"
#import "ReshetPlayerViewController.h"

@interface Reshet_MediaPlayerAdapter()

@property (nonatomic, strong) ReshetPlayerViewController *playerVC;
@property (nonatomic, strong) KMA_Player_Meta *meta;

@end

@implementation Reshet_MediaPlayerAdapter

- (Reshet_MediaPlayerAdapter*)adapter:(ReshetPlayerViewController *)player {
    _playerVC = player;
    return [super init];
}

#pragma KMA_StreamAdapter Protocol

//-(KMA_Player_Meta* )getMeta {
//    NSDictionary *params = self.playerVC.artiParams;
//    _meta = [[KMA_Player_Meta alloc] init];
//    _meta.playername = params[@"kantart player name"];//@"ReshetPlayerViewController";
//    _meta.playerversion = params[@"kantar_player_version"];
//    _meta.screenwidth = [self getWidth];
//    _meta.screenheight = [self getHeight];
//    return _meta;
//}

- (int) getPosition {
    APQueuePlayer *queuePlayer = _playerVC.playerController.player;
    int livePosition = CMTimeGetSeconds(queuePlayer.player.currentItem.currentTime);
    if(livePosition < 0) livePosition = 0;
    return livePosition;
}

- (int) getDuration {
    APQueuePlayer *queuePlayer = _playerVC.playerController.player;
    return CMTimeGetSeconds(queuePlayer.player.currentItem.duration);
}

- (int) getWidth {
    return _playerVC.view.bounds.size.width;
}

- (int) getHeight {
    return _playerVC.view.bounds.size.height;
}

-(BOOL) isCastingEnabled{
    return NO;
}
@end


