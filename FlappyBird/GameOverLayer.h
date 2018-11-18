//
//  GameOverLayer.h
//  FlappyBird
//
//  Created by Srikanth KV on 22/02/14.
//  Copyright (c) 2014 mytechspace. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "GameHelperLayer.h"

typedef NS_ENUM(NSUInteger, GameOverLayerButtonType)
{
    GameOverLayerPlayButton = 0
};


@protocol GameOverLayerDelegate;
@interface GameOverLayer : GameHelperLayer
@property (nonatomic, assign) id<GameOverLayerDelegate> delegate;
@end


//**********************************************************************
@protocol GameOverLayerDelegate <NSObject>
@optional

- (void) gameOverLayer:(GameOverLayer*)sender tapRecognizedOnButton:(GameOverLayerButtonType) gameOverLayerButtonType;
@end