//
//  StartGameLayer.h
//  FlappyBird
//
//  Created by Srikanth KV on 22/02/14.
//  Copyright (c) 2014 mytechspace. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "GameHelperLayer.h"

typedef NS_ENUM(NSUInteger, StartGameLayerButtonType)
{
    StartGameLayerPlayButton = 0
};


@protocol StartGameLayerDelegate;
@interface StartGameLayer : GameHelperLayer
@property (nonatomic, assign) id<StartGameLayerDelegate> delegate;
@end


//**********************************************************************
@protocol StartGameLayerDelegate <NSObject>
@optional

- (void) startGameLayer:(StartGameLayer*)sender tapRecognizedOnButton:(StartGameLayerButtonType) startGameLayerButton;
@end