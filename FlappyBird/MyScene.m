//
//  MyScene.m
//  FlappyBird
//
//  Created by Srikanth KV on 20/02/14.
//  Copyright (c) 2014 mytechspace. All rights reserved.
//

#import "MyScene.h"
#import "StartGameLayer.h"
#import "GameOverLayer.h"

#define TIME 1.5
#define MINIMUM_PILLER_HEIGHT 50.0f
#define GAP_BETWEEN_TOP_AND_BOTTOM_PILLER 100.0f

#define PILLARS     @"Pillars"
#define UPWARD_PILLER @"Upward_Green_Pipe"
#define Downward_PILLER @"Downward_Green_Pipe"

#define BOTTOM_BACKGROUND_Z_POSITION    100
#define START_GAME_LAYER_Z_POSITION     150
#define GAME_OVER_LAYER_Z_POSITION      200

static const uint32_t pillerCategory            =  0x1 << 0;
static const uint32_t flappyBirdCategory        =  0x1 << 1;
static const uint32_t bottomBackgroundCategory  =  0x1 << 2;

static const float BG_VELOCITY = (TIME * 60);

static inline CGPoint CGPointAdd(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a, const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

@interface MyScene() <SKPhysicsContactDelegate,
                      StartGameLayerDelegate,
                      GameOverLayerDelegate>
{
    NSTimeInterval _dt;
    float bottomScrollerHeight;
    
    BOOL _gameStarted;
    BOOL _gameOver;
    
    StartGameLayer* _startGameLayer;
    GameOverLayer* _gameOverLayer;
    
    int _score;
}
@property (nonatomic) SKSpriteNode* backgroundImageNode;
@property (nonatomic) SKSpriteNode* flappyBird;

@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;

@property (nonatomic) NSArray* flappyBirdFrames;
@end


@implementation MyScene

#pragma mark - Initializations
-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        //Initialize the static background
        [self initializeBackGround:size];
        
        //Initialize moving background
        [self initalizingScrollingBackground];
        
        //Initialize Bird
        [self initializeBird];
        
        [self initializeStartGameLayer];
        [self initializeGameOverLayer];
        
        //Set gravity to 0 so that bird remains in its position in start page
        self.physicsWorld.gravity = CGVectorMake(0, 0.0);
        
        //To detect collision detection
        self.physicsWorld.contactDelegate = self;
        
        _gameOver = NO;
        _gameStarted = NO;
        [self showStartGameLayer];
    }
    return self;
}

- (void) initializeBackGround:(CGSize) sceneSize
{
    self.backgroundImageNode = [SKSpriteNode spriteNodeWithImageNamed:@"Night_Background"];
    self.backgroundImageNode.size = sceneSize;
    self.backgroundImageNode.position = CGPointMake(self.backgroundImageNode.size.width/2, self.frame.size.height/2);
    [self addChild:self.backgroundImageNode];
}

-(void)initalizingScrollingBackground
{
    for (int i = 0; i < 2; i++)
    {
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"Bottom_Scroller"];
        bg.zPosition = BOTTOM_BACKGROUND_Z_POSITION;
        bottomScrollerHeight = bg.size.height;
        bg.position = CGPointMake((i * bg.size.width) + (bg.size.width * 0.5f) - 1, bg.size.height * 0.5f);
        bg.name = @"bg";
        
        /*
         * Create a physics and specify its geometrical shape so that collision algorithm can work more prominently
         */
        bg.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bg.size];
        
        //Category to which this object belongs to
        bg.physicsBody.categoryBitMask = bottomBackgroundCategory;
        
        //To notify intersection with objects
        bg.physicsBody.contactTestBitMask = flappyBirdCategory;
        
        //To detect collision with category of objects
        bg.physicsBody.collisionBitMask = 0;
        
        /*
         * Has to be explicitely mentioned. If not mentioned, bg starts moving down because of gravity.
         */
        bg.physicsBody.affectedByGravity = NO;
        [self addChild:bg];
    }
}

#pragma mark -Initialize Bird
- (void)initializeBird
{
    NSMutableArray *flappyBirdFrames = [NSMutableArray array];
    for (int i = 0; i < 3; i++)
    {
        NSString* textureName = nil;
        switch (i)
        {
            case 0:
            {
                textureName = @"Yellow_Bird_Wing_Up";
                break;
            }
            case 1:
            {
                textureName = @"Yellow_Bird_Wing_Straight";
                break;
            }
            case 2:
            {
                textureName = @"Yellow_Bird_Wing_Down";
                break;
            }
            default:
                break;
        }
        
        SKTexture* texture = [SKTexture textureWithImageNamed:textureName];
        [flappyBirdFrames addObject:texture];
    }
    [self setFlappyBirdFrames:flappyBirdFrames];
    
    self.flappyBird = [SKSpriteNode spriteNodeWithTexture:[_flappyBirdFrames objectAtIndex:1]];
    
    /*
     * Create a physics and specify its geometrical shape so that collision algorithm
     * can work more prominently
     */
    _flappyBird.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_flappyBird.size];
    
    //Category to which this object belongs to
    _flappyBird.physicsBody.categoryBitMask = flappyBirdCategory;
    
    //To notify intersection with objects
    _flappyBird.physicsBody.contactTestBitMask = pillerCategory | bottomBackgroundCategory;
    
    //To detect collision with category of objects
    _flappyBird.physicsBody.collisionBitMask = 0;
    
    [self addChild:self.flappyBird];
}

- (void) flyingBird
{
    //This is our general runAction method to make our flappy bird fly.
    [_flappyBird runAction:[SKAction repeatActionForever:
                      [SKAction animateWithTextures:_flappyBirdFrames
                                       timePerFrame:0.15f
                                             resize:NO
                                            restore:YES]] withKey:@"flyingFlappyBird"];
    return;
}

#pragma mark -Initialize Helper Layers
- (void) initializeStartGameLayer
{
    _startGameLayer = [[StartGameLayer alloc]initWithSize:self.size];
    _startGameLayer.userInteractionEnabled = YES;
    _startGameLayer.zPosition = START_GAME_LAYER_Z_POSITION;
    _startGameLayer.delegate = self;
}

- (void) initializeGameOverLayer
{
    _gameOverLayer = [[GameOverLayer alloc]initWithSize:self.size];
    _gameOverLayer.userInteractionEnabled = YES;
    _gameOverLayer.zPosition = GAME_OVER_LAYER_Z_POSITION;
    _gameOverLayer.delegate = self;
}

#pragma mark - GameStatus calls
- (void) showStartGameLayer
{
    //Remove currently exising on pillars from scene and purge them
    for (int i = self.children.count - 1; i >= 0; i--)
    {
        SKNode* childNode = [self.children objectAtIndex:i];
        if(childNode.physicsBody.categoryBitMask == pillerCategory)
        {
            [childNode removeFromParent];
        }
    }
    
    //Move Flappy Bird node to center of the scene
    self.flappyBird.position = CGPointMake(self.backgroundImageNode.size.width * 0.5f, self.frame.size.height * 0.6f);
    
    [_gameOverLayer removeFromParent];
    
    _flappyBird.hidden = NO;
    [self flyingBird];
    [self addChild:_startGameLayer];
}

- (void) showGameOverLayer
{
    //Remove currently exising on pillars from scene and purge them
    for (int i = self.children.count - 1; i >= 0; i--)
    {
        SKNode* childNode = [self.children objectAtIndex:i];
        if(childNode.physicsBody.categoryBitMask == pillerCategory)
        {
            [childNode removeAllActions];
        }
    }
    
    [_flappyBird removeAllActions];
    _flappyBird.physicsBody.velocity = CGVectorMake(0, 0);
    self.physicsWorld.gravity = CGVectorMake(0, 0.0);
    _flappyBird.hidden = YES;
    
    _gameOver = YES;
    _gameStarted = NO;
    
    _dt = 0;
    _lastUpdateTimeInterval = 0;
    _lastSpawnTimeInterval = 0;
    
    [_startGameLayer removeFromParent];
    [self addChild:_gameOverLayer];
}

- (void) startGame
{
    _score = 0;
    
    _gameStarted = YES;
    
    [_startGameLayer removeFromParent];
    [_gameOverLayer removeFromParent];
    
    self.flappyBird.position = CGPointMake(self.backgroundImageNode.size.width * 0.3f, self.frame.size.height * 0.6f);
    
    //To have Gravity effect on Bird so that bird flys down when not tapped
    self.physicsWorld.gravity = CGVectorMake(0, -4.0);
}

#pragma mark - Pillar
- (void)addAPiller
{
    //Create Upward directed pillar
    SKSpriteNode* upwardPiller = [self createPillerWithUpwardDirection:YES];
    
    int minY = MINIMUM_PILLER_HEIGHT;
    int maxY = self.frame.size.height - bottomScrollerHeight - GAP_BETWEEN_TOP_AND_BOTTOM_PILLER - MINIMUM_PILLER_HEIGHT;
    int rangeY = maxY - minY;
    
    float upwardPillerY = ((arc4random() % rangeY) + minY) - upwardPiller.size.height;
    upwardPillerY += bottomScrollerHeight;
    upwardPillerY += upwardPiller.size.height * 0.5f;
    
    /*Set position of pillar start position outside the screen so that we can be 
     sure that image is created before it comes inside screen visibility area
     */
    upwardPiller.position = CGPointMake(self.frame.size.width + upwardPiller.size.width/2, upwardPillerY);
    
    
    //Create Downward directed pillar
    SKSpriteNode* downwardPiller = [self createPillerWithUpwardDirection:NO];
    float downloadPillerY = upwardPillerY + upwardPiller.size.height + GAP_BETWEEN_TOP_AND_BOTTOM_PILLER;
    downwardPiller.position = CGPointMake(upwardPiller.position.x, downloadPillerY);
    
    
    /*
     * Create Upward Piller actions.
     * First action has to be the movement of pillar. Right to left.
     * Once first action is complete, remove that node from Scene
     */
    SKAction * upwardPillerActionMove = [SKAction moveTo:CGPointMake(-upwardPiller.size.width/2, upwardPillerY) duration:(TIME * 2)];
    SKAction * upwardPillerActionMoveDone = [SKAction removeFromParent];
    [upwardPiller runAction:[SKAction sequence:@[upwardPillerActionMove, upwardPillerActionMoveDone]]];
    
    
    // Create Downward Piller actions
    SKAction * downwardPillerActionMove = [SKAction moveTo:CGPointMake(-downwardPiller.size.width/2, downloadPillerY) duration:(TIME * 2)];
    SKAction * downwardPillerActionMoveDone = [SKAction removeFromParent];
    [downwardPiller runAction:[SKAction sequence:@[downwardPillerActionMove, downwardPillerActionMoveDone]]];
}

- (SKSpriteNode*) createPillerWithUpwardDirection:(BOOL) isUpwards
{
    NSString* pillerImageName = nil;
    if (isUpwards)
    {
        pillerImageName = UPWARD_PILLER;
    }
    else
    {
        pillerImageName = Downward_PILLER;
    }
    
    SKSpriteNode * piller = [SKSpriteNode spriteNodeWithImageNamed:pillerImageName];
    piller.name = PILLARS;
    
    /*
     * Create a physics and specify its geometrical shape so that collision algorithm
     * can work more prominently
     */
    piller.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:piller.size];
    
    //Category to which this object belongs to
    piller.physicsBody.categoryBitMask = pillerCategory;
    
    //To notify intersection with objects
    piller.physicsBody.contactTestBitMask = flappyBirdCategory;
    
    //To detect collision with category of objects. Default all categories
    piller.physicsBody.collisionBitMask = 0;
    
    /*
     * Has to be explicitely mentioned. If not mentioned, pillar starts moving down becuase of gravity.
     */
    piller.physicsBody.affectedByGravity = NO;
    
    [self addChild:piller];
    
    return piller;
}

#pragma mark - Bottom Background
- (void)moveBottomScroller
{
    [self enumerateChildNodesWithName:@"bg" usingBlock: ^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode * bg = (SKSpriteNode *) node;
         CGPoint bgVelocity = CGPointMake(-BG_VELOCITY, 0);
         CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity,_dt);
         bg.position = CGPointAdd(bg.position, amtToMove);
         
         //Checks if bg node is completely scrolled of the screen, if yes then put it at the end of the other node
         if (bg.position.x + bg.size.width * 0.5f <= 0)
         {
             bg.position = CGPointMake(bg.size.width*2 - (bg.size.width * 0.5f) - 2,
                                       bg.position.y);
         }
     }];
}

#pragma mark - Update
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast
{
    self.lastSpawnTimeInterval += timeSinceLast;
    if (self.lastSpawnTimeInterval > TIME)
    {
        self.lastSpawnTimeInterval = 0;
        [self addAPiller];
    }
}

- (void)update:(NSTimeInterval)currentTime
{
    if(_gameOver == NO)
    {
        if (self.lastUpdateTimeInterval)
        {
            _dt = currentTime - _lastUpdateTimeInterval;
        }
        else
        {
            _dt = 0;
        }
        
        CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
        self.lastUpdateTimeInterval = currentTime;
        if (timeSinceLast > TIME)
        {
            timeSinceLast = 1.0 / (TIME * 60.0);
            self.lastUpdateTimeInterval = currentTime;
        }
        
        [self moveBottomScroller];
        [self updateScore];
        
        if(_gameStarted)
        {
            [self updateWithTimeSinceLastUpdate:timeSinceLast];
        }
    }
}

#pragma mark - Collision Detection
- (void)pillar:(SKSpriteNode *)pillar didCollideWithBird:(SKSpriteNode *)bird
{
    [self showGameOverLayer];
}

- (void)flappyBird:(SKSpriteNode *)bird didCollideWithBottomScoller:(SKSpriteNode *)bottomBackground
{
    [self showGameOverLayer];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask & pillerCategory) != 0 &&
        (secondBody.categoryBitMask & flappyBirdCategory) != 0)
    {
        [self pillar:(SKSpriteNode *) firstBody.node didCollideWithBird:(SKSpriteNode *) secondBody.node];
    }
    else if ((firstBody.categoryBitMask & flappyBirdCategory) != 0 &&
            (secondBody.categoryBitMask & bottomBackgroundCategory) != 0)
    {
        [self flappyBird:(SKSpriteNode *)firstBody.node didCollideWithBottomScoller:(SKSpriteNode *)secondBody.node];
    }
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_gameStarted && _gameOver == NO)
    {
        _flappyBird.physicsBody.velocity = CGVectorMake(0, 250);
    }
}

#pragma mark - Delegates
#pragma mark -StartGameLayer
- (void)startGameLayer:(StartGameLayer *)sender tapRecognizedOnButton:(StartGameLayerButtonType)startGameLayerButton
{
    _gameOver = NO;
    _gameStarted = YES;
    
    [self startGame];
}

- (void)gameOverLayer:(GameOverLayer *)sender tapRecognizedOnButton:(GameOverLayerButtonType)gameOverLayerButtonType
{
    _gameOver = NO;
    _gameStarted = NO;
    [self showStartGameLayer];
}

#pragma mark - Update Score
- (void) updateScore
{
    [self enumerateChildNodesWithName:PILLARS usingBlock:^(SKNode *node, BOOL *stop)
    {
        if(_flappyBird.position.x > node.position.x)
        {
            node.name = @"";    //Reset the name to empty name so as to not track the pillar once it has passed beyond the bird's position
            
            ++_score;
            
            /* Since there are 2 pillars(Top and bottom), we will this function will be fired 2 times.
             * So we take a reminder by dividing the current score with 2
             */
            if (_score % 2 == 0)
            {
                NSLog(@"Score: %d", _score/2);
            }
            
            *stop = YES;    //To stop enumerating
        }
    }];
}

@end
