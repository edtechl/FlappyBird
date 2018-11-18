//
//  GameOverLayer.m
//  FlappyBird
//
//  Created by Srikanth KV on 22/02/14.
//  Copyright (c) 2014 mytechspace. All rights reserved.
//

#import "GameOverLayer.h"

@interface GameOverLayer()
@property (nonatomic, retain) SKSpriteNode* retryButton;
@end

@implementation GameOverLayer

- (id)initWithSize:(CGSize)size
{
    if(self = [super initWithSize:size])
    {
        SKSpriteNode* startGameText = [SKSpriteNode spriteNodeWithImageNamed:@"GameOverText"];
        startGameText.position = CGPointMake(size.width * 0.5f, size.height * 0.8f);
        [self addChild:startGameText];
        
        SKSpriteNode* retryButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        retryButton.position = CGPointMake(size.width * 0.5f, size.height * 0.30f);
        [self addChild:retryButton];
        
        [self setRetryButton:retryButton];
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    if ([_retryButton containsPoint:location])
    {
        if([self.delegate respondsToSelector:@selector(gameOverLayer:tapRecognizedOnButton:)])
        {
            [self.delegate gameOverLayer:self tapRecognizedOnButton:GameOverLayerPlayButton];
        }
    }
}

@end
