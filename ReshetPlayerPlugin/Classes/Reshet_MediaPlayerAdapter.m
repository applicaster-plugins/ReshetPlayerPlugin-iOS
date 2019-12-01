//
//  Reshet_MediaPlayerAdapter.m
//  KMA_SpringStreams
//
//  Created by Frank Kammann on 26.08.11.
//  Copyright 2011 spring GmbH & Co. KG. All rights reserved.
//



#import "KMA_SpringStreams.h"
#import "ReshetPlayerViewController.h"

@implementation Reshet_MediaPlayerAdapter

ReshetPlayerViewController *controller;
//KMA_Player_Meta *meta;

- (Reshet_MediaPlayerAdapter*)adapter:(ReshetPlayerViewController *)player {
//    meta = [[KMA_Player_Meta alloc] init];
//    meta.playername = @"ReshetPlayerViewController";
    controller = player;
    return [super init];
}

#pragma KMA_StreamAdapter Protocol

- (int) getPosition {
    APQueuePlayer *queuePlayer = controller.playerController.player;
    int livePosition = CMTimeGetSeconds(queuePlayer.player.currentItem.currentTime);
    if(livePosition < 0) livePosition = 0;
    return livePosition;
}

- (int) getDuration {
    APQueuePlayer *queuePlayer = controller.playerController.player;
    return CMTimeGetSeconds(queuePlayer.player.currentItem.duration);
}

- (int) getWidth {
    return controller.view.bounds.size.width;
}

- (int) getHeight {
    return controller.view.bounds.size.height;
}

-(BOOL) isCastingEnabled{
    return NO;
}
@end


