//
//  BTJoypadViewController_iPad.m
//  BTJoypad
//
//  Created by sap_all\c5152815 on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BTJoypadViewController_iPad.h"
#import "PlayerViewController.h"
#import "LaserViewController.h"
#import "RocketViewController.h"
#import "AsteroidViewController.h"

#define BOUNCE_TIME 1.0
#define NUM_PLAYER 2
#define PLAYER_1_IDX 0
#define PLAYER_2_IDX 1

#define OBJECT_TYPE_LASER 0
#define OBJECT_TYPE_ASTEROID 1
#define OBJECT_TYPE_ROCKET 2
#define OBJECT_TYPE_ROCKET_COLLECTIBLE 3

#define HIT_LASER_DECREASE 0.1
#define HIT_PLANE_PLANE_DECREASE 0.05

#define SCORE_LASER_HIT_PLANE 10
#define SCORE_ROCKET_HIT_PLANE 20

// GameKit Session ID for app
#define kSessionID @"BTJoypad"

#define kALERT_CONNECT_CONFIRMATION 0


@interface BTJoypadViewController_iPad (private)

- (void)spawnRocket;
- (void)invalidateSession:(GKSession *)session;
- (void)printOutDescriptionAndSolutionOfError:(NSError *)error;

@end


@implementation BTJoypadViewController_iPad

@synthesize playerMutArray;
@synthesize laserMutArray;
@synthesize rocketMutArray;
@synthesize asteroidMutArray;
@synthesize laserSoundPlayer;
@synthesize explosionSoundPlayer;
@synthesize gameTimer;
@synthesize asteroidTimer;
@synthesize rocketTimer;
@synthesize joyPad1Base;
@synthesize joyPad1;
@synthesize joyPad2Base;
@synthesize joyPad2;
@synthesize p1ScoreLabel;
@synthesize p2ScoreLabel;
@synthesize p1ScoreView;
@synthesize p2ScoreView;
@synthesize rocketImgView;
@synthesize backgroundImgView;
@synthesize backgroundDuplicateImgView;
@synthesize backgroundRefImgView;
@synthesize currentSession;
@synthesize peerIdMutArray;
@synthesize sbJSON;
@synthesize winningScreenView;
@synthesize winnerLabel;
@synthesize btConnectP1;
@synthesize btConnectP2;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [playerMutArray release];
    [laserMutArray release];
    [rocketMutArray release];
    [asteroidMutArray release];
    [laserSoundPlayer release];
    [explosionSoundPlayer release];
    [gameTimer release];
    [asteroidTimer release];
    [rocketTimer release];
    [joyPad1Base release];
    [joyPad1 release];
    [joyPad2Base release];
    [joyPad2 release];        
    [p1ScoreLabel release];
    [p2ScoreLabel release];
    [p1ScoreView release];
    [p2ScoreView release];   
    [rocketImgView release];
    [backgroundImgView release];
    [backgroundDuplicateImgView release];
    [backgroundRefImgView release];   
    [currentSession release];
    [peerIdMutArray release];
    [sbJSON release];   
    [winningScreenView release];
    [winnerLabel release];
    [btConnectP1 release];
    [btConnectP2 release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    maxRadius = 84.0;
    maxRadiusAllowedOutSide = 179.0;  
    isJoypadWithinBounds = YES; 
    
    isJoypad1Pressed = NO;
    isJoypad2Pressed = NO;
    lastTime = 0;
    
    
    //==== initialize mutable arrays
    self.playerMutArray = [[NSMutableArray alloc] init];
    self.laserMutArray = [[NSMutableArray alloc] init];   
    self.rocketMutArray = [[NSMutableArray alloc] init];
    self.asteroidMutArray = [[NSMutableArray alloc] init];
    
    
    //==== Load Player objects
    for(int i=0; i < NUM_PLAYER; i++)
    {
        PlayerViewController *tempPlayerVC = (PlayerViewController *)[[PlayerViewController alloc] initWithNibName:@"PlayerViewController" bundle:nil];
        
        //add p1 plane to the view
        CGPoint planeOrigin = CGPointZero;
        
        if(i == 0)
        {
            planeOrigin = CGPointMake(50, 600);
            
        }
        else if(i==1)
        {
            planeOrigin = CGPointMake(50, 210);
        }
        
        tempPlayerVC.view.frame = CGRectMake(planeOrigin.x, planeOrigin.y, 
                                             tempPlayerVC.view.frame.size.width, 
                                             tempPlayerVC.view.frame.size.height);  
        
        
        tempPlayerVC.view.center = CGPointMake(self.view.center.x, tempPlayerVC.view.center.y);
        
        if(i == 0)
        {
            tempPlayerVC.planeImgView.image = [UIImage imageNamed:@"plane1.png"];
        }
        else if(i == 1)
        {
            tempPlayerVC.planeImgView.image = [UIImage imageNamed:@"plane2.png"];
            tempPlayerVC.view.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
        }
        
        [self.playerMutArray addObject:tempPlayerVC];
        [self.view insertSubview:tempPlayerVC.view atIndex:2];
        
        [tempPlayerVC release];
    }
    
    
    //==== add gesture recognizer to the joypad
    UIPanGestureRecognizer *panRecognizer_joypad1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    
    [self.joyPad1 addGestureRecognizer:panRecognizer_joypad1];
    
    [panRecognizer_joypad1 release];
    
    
    UIPanGestureRecognizer *panRecognizer_joypad2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    
    [self.joyPad2 addGestureRecognizer:panRecognizer_joypad2];
    
    [panRecognizer_joypad2 release];
    
    
	//==== SFX (laser)
	NSString *laserSoundFilePath = [[NSBundle mainBundle] pathForResource:@"blaster" ofType: @"wav"];
	NSURL *laserSoundFileURL = [[NSURL alloc] initFileURLWithPath:laserSoundFilePath];
	AVAudioPlayer *tempLaserSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:laserSoundFileURL error:nil];
	
	self.laserSoundPlayer = tempLaserSoundPlayer;
	
	[tempLaserSoundPlayer release];
	[laserSoundFileURL release];
    
    
    //==== SFX (explosion)
    NSString *explosionSoundFilePath = [[NSBundle mainBundle] pathForResource:@"explosion" ofType:@"wav"];
    NSURL *explosionSoundFileURL = [[NSURL alloc] initFileURLWithPath:explosionSoundFilePath];
    AVAudioPlayer *tempExplosionSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:explosionSoundFileURL error:nil];
    
    self.explosionSoundPlayer = tempExplosionSoundPlayer;
    
    [tempExplosionSoundPlayer release];
    [explosionSoundFileURL release];
    
    
    //=== flip p2 score view
    self.p2ScoreView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    
    
	//==== prepare sounds
	[self.laserSoundPlayer prepareToPlay];  
    [self.explosionSoundPlayer prepareToPlay];
    
    
    //=== initialize SBJSON
    self.sbJSON = [[SBJSON alloc] init];
    self.sbJSON.humanReadable = YES;   
    
    //=== initialize peer ID mutable array
    self.peerIdMutArray = [NSMutableArray array];
    
    
    //== initialize variables
    SHOULD_GENERATE_ASTEROID = FALSE;   
    IS_GAME_STARTED = FALSE;
    REMOTE_ATTEMPT_PEER_ID = @"";
    
    
    //=== position rocket
    self.rocketImgView.center = CGPointMake(-100, 350);
    ROCKET_MOVE_VECTOR = CGPointMake(0, 0);
    ROCKET_SPEED = 5.0;
    lastRocketTime = CFAbsoluteTimeGetCurrent();
    
    
    
    //remove winning screen
    self.winningScreenView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    [self.winningScreenView removeFromSuperview];
    
    
    
    //we're good to go, start the timer
    /*
     
    self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:1/30.0 target:self selector:@selector(mainGameLoop) userInfo:nil repeats:YES];
    
    self.asteroidTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(asteroidTimerCall) userInfo:nil repeats:YES];  
    
    self.rocketTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(rocketTimerCall) userInfo:nil repeats:YES];
     
     */
    
    
    //set background reference
    self.backgroundRefImgView = self.backgroundImgView;
    
    /*
     peerPicker = [[GKPeerPickerController alloc] init];
     peerPicker.delegate = self;
     peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
     
     [peerPicker show]; 
     */  
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown;
}


#pragma mark - Application logic


float bgSlideFactor = 10.0;

- (void)mainGameLoop
{
    //make sure we have frame-independent update
    //double deltaTime = CFAbsoluteTimeGetCurrent() - lastTime;
    

     if(IS_GAME_STARTED)
     {
         //move the background
         self.backgroundImgView.center = CGPointMake(self.backgroundImgView.center.x, self.backgroundImgView.center.y + bgSlideFactor);
         self.backgroundDuplicateImgView.center = CGPointMake(self.backgroundDuplicateImgView.center.x, self.backgroundDuplicateImgView.center.y + bgSlideFactor);
         
         
         if(self.backgroundImgView.frame.origin.y > 1020)
         {
             //move back
             self.backgroundImgView.frame = CGRectMake(0, -1010, self.backgroundImgView.frame.size.width, self.backgroundImgView.frame.size.height);
         }
         
         if(self.backgroundDuplicateImgView.frame.origin.y > 1020)
         {
             //move back
             self.backgroundDuplicateImgView.frame = CGRectMake(0, -1010, self.backgroundDuplicateImgView.frame.size.width, self.backgroundDuplicateImgView.frame.size.height);
         }         
         
         //=== PLAYER
         
         if(isJoypad1Pressed)
         {
             [self updatePlayerWithIndex:PLAYER_1_IDX];
         }
         
         if(isJoypad2Pressed)
         {
             [self updatePlayerWithIndex:PLAYER_2_IDX];
         }
         
         
         //=== ASTEROID
         
         for(int i=0; i < [self.asteroidMutArray count]; i++)
         {
             AsteroidViewController *asteroidVC = (AsteroidViewController *)[self.asteroidMutArray objectAtIndex:i];
             
             if(asteroidVC.positionType == 0)
             {
                 //from left side, rotate clockwise
                 
                 asteroidVC.view.transform = CGAffineTransformRotate(asteroidVC.view.transform, DEGREES_TO_RADIANS(5));
                 
                 CGPoint astMoveVector = CGPointMake(1, 1);
                 float astSpeed = 3.0;
                 
                 asteroidVC.view.center = CGPointMake(asteroidVC.view.center.x + astMoveVector.x * astSpeed, asteroidVC.view.center.y + astMoveVector.y * astSpeed);
             }
             else if(asteroidVC.positionType == 1)
             {
                 //from right side, rotate counter-clockwise
                 
                 asteroidVC.view.transform = CGAffineTransformRotate(asteroidVC.view.transform, DEGREES_TO_RADIANS(-5));
                 
                 CGPoint astMoveVector = CGPointMake(-1, -1);
                 float astSpeed = 3.0;
                 
                 asteroidVC.view.center = CGPointMake(asteroidVC.view.center.x + astMoveVector.x * astSpeed, asteroidVC.view.center.y + astMoveVector.y * astSpeed);    
             }
             
             
             //check asteroid - plane collision
             BOOL isIntersecting = [self isRectIntersectPlane:asteroidVC.view.frame withType:OBJECT_TYPE_ASTEROID];
             
             if(isIntersecting)
             {
                 NSLog(@"intersecting with asteroid");
                 
                 [asteroidVC.view removeFromSuperview];
                 
                 
                 //play explosion
                 [self explodeOnPoint:asteroidVC.view.center];
                 
                 //hit plane, remove !
                 [asteroidVC.view removeFromSuperview];
                 [self.asteroidMutArray removeObjectAtIndex:i];   
             }
         }//end update asteroid
         
         //=== ROCKET (collectibles)
         
         //update rocket position        
         self.rocketImgView.center = CGPointMake(self.rocketImgView.center.x + ROCKET_MOVE_VECTOR.x * ROCKET_SPEED, self.rocketImgView.center.y + ROCKET_MOVE_VECTOR.y * ROCKET_SPEED);
         
         {
             BOOL isIntersecting = [self isRectIntersectPlane:self.rocketImgView.frame withType:OBJECT_TYPE_ROCKET_COLLECTIBLE];
             
             if(isIntersecting)
             {
                 NSLog(@"is intersecting with rocket collectible");
                 
                 //remove the rocket collectible
                 self.rocketImgView.frame = CGRectMake(-1000, -1000, 
                                                       self.rocketImgView.frame.size.width, 
                                                       self.rocketImgView.frame.size.height);
                 [self.rocketImgView removeFromSuperview];
             }
         }//end update rocket collectibles
         
         
         //=== ROCKET (shootout)
         for(int i=0; i < [self.rocketMutArray count]; i++)
         {
             RocketViewController *rocketVC = (RocketViewController *)[self.rocketMutArray objectAtIndex:i];
             
             rocketVC.view.center = CGPointMake(rocketVC.view.center.x + rocketVC.moveVector.x * rocketVC.speed, 
                                                rocketVC.view.center.y + rocketVC.moveVector.y * rocketVC.speed);
             
             if(rocketVC.view.superview == nil)
             {
                 [self.view addSubview:rocketVC.view];
             }
             
             if([self isPointOutOfScreen:rocketVC.view.center])
             {
                 //play explosion animation
                 [self explodeOnPoint:rocketVC.view.center];
                 
                 //out of bounds, remove !
                 [rocketVC.view removeFromSuperview];
                 [self.rocketMutArray removeObjectAtIndex:i];
             }
             else
             {
                 BOOL isIntersecting = [self isRectIntersectPlane:rocketVC.view.frame withType:OBJECT_TYPE_ROCKET];
                 
                 if(isIntersecting)
                 {
                     //play explosion
                     [self explodeOnPoint:rocketVC.view.center];
                     
                     //hit plane, remove !
                     [rocketVC.view removeFromSuperview];
                     [self.rocketMutArray removeObjectAtIndex:i];
                 }
             }
         }//end update rocket shoot
         
         //=== LASER
         
         //update laser position
         for (int i=0; i < [self.laserMutArray count]; i++) {
             
             LaserViewController *laserVC = (LaserViewController *)[self.laserMutArray objectAtIndex:i];
             
             laserVC.view.center = CGPointMake(laserVC.view.center.x + laserVC.moveVector.x * laserVC.speed,
                                               laserVC.view.center.y + laserVC.moveVector.y * laserVC.speed);
             
             if(laserVC.view.superview == nil)
             {
                 [self.view addSubview:laserVC.view];
             }
             
             
             if ([self isPointOutOfScreen:laserVC.view.center]) {
                 
                 //play explosion animation
                 [self explodeOnPoint:laserVC.view.center];            
                 
                 //out of bounds, remove !
                 [laserVC.view removeFromSuperview];
                 [self.laserMutArray removeObjectAtIndex:i];
             }
             else
             {
                 //if the laser hit plane
                 BOOL isIntersecting = [self isRectIntersectPlane:laserVC.view.frame withType:OBJECT_TYPE_LASER];
                 
                 if(isIntersecting)
                 {
                     //play explosion animation
                     [self explodeOnPoint:laserVC.view.center];     
                     
                     
                     //hit plane, remove !
                     [laserVC.view removeFromSuperview];
                     [self.laserMutArray removeObjectAtIndex:i];      
                     
                     
                     for(int i=0; i < NUM_PLAYER; i++)
                     {
                         PlayerViewController *playerVC = (PlayerViewController *)[self.playerMutArray objectAtIndex:i];
                         
                         NSLog(@"player %d: health:%f", i, playerVC.healthProgressView.progress);
                     }
                 }
             }
         } // end update laser           
         
        
     }//end IS_GAME_STARTED 
 
    
 
    //update 'lastTime'
    lastTime = CFAbsoluteTimeGetCurrent();
}

- (void)asteroidTimerCall
{
    //random
    int randPosVal = (arc4random() % 2);
    //float randY = (arc4random() % 1000) + 24;
    float randY = (arc4random() % 1000);
    float posX = 0.0;
    int posType = -1;
    
    NSLog(@"(asteroid) randPosVal: %d", randPosVal);
    //NSLog(@"(asteroid) randY: %f", randY);
    
    if(randPosVal == 0)
    {
        posX = -25.0;
        posType = 0;
    }
    else if(randPosVal == 1)
    {
        posX = 725.0;
        posType = 1;
    }
    
    AsteroidViewController *tempAsteroidVC = [[AsteroidViewController alloc] initWithNibName:@"AsteroidViewController" bundle:nil];
    tempAsteroidVC.view.frame = CGRectMake(posX, randY, tempAsteroidVC.view.frame.size.width, tempAsteroidVC.view.frame.size.height);
    
    tempAsteroidVC.centerStartPoint = CGPointMake(tempAsteroidVC.view.center.x, tempAsteroidVC.view.center.y);
    tempAsteroidVC.positionType = posType;
    
    [self.view insertSubview:tempAsteroidVC.view atIndex:2];
    [self.asteroidMutArray addObject:tempAsteroidVC];
    
    [tempAsteroidVC release];
}


- (void)rocketTimerCall
{
    double deltaIdleRocketTime = CFAbsoluteTimeGetCurrent() - lastRocketTime;
    
    //more than 5 seconds, spawn a rocket
    if(deltaIdleRocketTime > 4.9)
    {
        lastRocketTime = CFAbsoluteTimeGetCurrent();
        
        [self spawnRocket];
    }
}


- (void)spawnRocket
{
    int randPosVal = (arc4random() % 2);
    int randY_int = arc4random() % 768;
    
    float moveVector_X = sinf(DEGREES_TO_RADIANS(arc4random() % 91));
    float moveVector_Y = cosf(DEGREES_TO_RADIANS((arc4random() % 91) + 45));
    
    if(randPosVal == 0)
    {
        //spawn on the left side of the screen
        
        self.rocketImgView.center = CGPointMake(-100, randY_int);
        ROCKET_MOVE_VECTOR = CGPointMake(moveVector_X, moveVector_Y);
    }
    else if(randPosVal == 1)
    {
        //spawn on the right side of the screen
        
        self.rocketImgView.center = CGPointMake(1124, randY_int);
        ROCKET_MOVE_VECTOR = CGPointMake(-moveVector_X, moveVector_Y);
    }
    
    [self.view insertSubview:self.rocketImgView atIndex:2];
}

- (void)updatePlayerWithIndex:(int)playerIdx
{
    PlayerViewController *playerVC = (PlayerViewController *)[self.playerMutArray objectAtIndex:playerIdx];
    
    //Type 1: Plane move within the bounds of screen
    if(! playerVC.isBounceActive)
    {
        if(playerVC.smoothMoveFactor < 1.0)
            playerVC.smoothMoveFactor += 0.1f;
        
        float movementOffsetX = 0;
        float movementOffsetY = 0;
        
        
        if (playerIdx == PLAYER_1_IDX) {
            movementOffsetX = (float)_TOUCH_DISTANCE_JOYPAD1/10.0f * cosf(_TOUCH_ANGLE_JOYPAD1);
            movementOffsetY = (float)_TOUCH_DISTANCE_JOYPAD1/10.0f * sinf(_TOUCH_ANGLE_JOYPAD1);       
        }
        else if(playerIdx == PLAYER_2_IDX)
        {
            movementOffsetX = -(float)_TOUCH_DISTANCE_JOYPAD2/10.0f * cosf(_TOUCH_ANGLE_JOYPAD2);
            movementOffsetY = -(float)_TOUCH_DISTANCE_JOYPAD2/10.0f * sinf(_TOUCH_ANGLE_JOYPAD2);           
        }
        
        movementOffsetX *= playerVC.smoothMoveFactor;
        movementOffsetY *= playerVC.smoothMoveFactor;
        
        
        playerVC.newLocation = CGPointMake(playerVC.view.center.x - movementOffsetX, 
                                           playerVC.view.center.y - movementOffsetY);
        
        
        playerVC.moveVector = CGPointMake(playerVC.newLocation.x - playerVC.view.center.x, 
                                          playerVC.newLocation.y - playerVC.view.center.y);
        
        
        //check plane-plane collision
        //other player VC
        PlayerViewController *playerVC_other = (PlayerViewController *)[self.playerMutArray objectAtIndex:(NUM_PLAYER - 1) - playerIdx];
        
        //redefine hit area
        CGRect hitAreaRect_p1 = CGRectMake(playerVC.view.frame.origin.x + playerVC.hitAreaView.frame.origin.x, 
                                           playerVC.view.frame.origin.y + playerVC.hitAreaView.frame.origin.y, 
                                           playerVC.hitAreaView.frame.size.width, 
                                           playerVC.hitAreaView.frame.size.height + 100); 
        
        
        CGRect hitAreaRect_p2 = CGRectMake(playerVC_other.view.frame.origin.x + playerVC_other.hitAreaView.frame.origin.x, 
                                           playerVC_other.view.frame.origin.y + playerVC_other.hitAreaView.frame.origin.y, 
                                           playerVC_other.hitAreaView.frame.size.width, 
                                           playerVC_other.hitAreaView.frame.size.height + 100);    
        
        //bounce on top/bottom screen or on hit with other plane
        
        if(playerVC.newLocation.y < 0 || playerVC.newLocation.y > 1000 || CGRectIntersectsRect(hitAreaRect_p1, hitAreaRect_p2))
        { 
            playerVC.isBounceActive = TRUE;
            playerVC.smoothMoveFactor = -1.0f;
            playerVC.lastBounceTime = CFAbsoluteTimeGetCurrent();
            
            if(CGRectIntersectsRect(hitAreaRect_p1, hitAreaRect_p2))
            {
                NSLog(@"plane - plane intersection");
                
                playerVC.healthProgressView.progress -= 0.1;
                playerVC_other.healthProgressView.progress -= 0.1;
            }
        }
        
        //wrap around left/right
        
        if((playerVC.newLocation.x - playerVC.view.frame.size.width * 0.5) > self.view.frame.size.width)
        {
            playerVC.newLocation = CGPointMake(- playerVC.view.frame.size.width + 100, playerVC.newLocation.y);
        }
        else if((playerVC.newLocation.x + playerVC.view.frame.size.width * 0.5)  < 0)
        {
            playerVC.newLocation = CGPointMake(self.view.frame.size.width + 100, playerVC.newLocation.y);
        }      
    }
    else if(playerVC.isBounceActive)
    {
        double curTime = CFAbsoluteTimeGetCurrent();
        double bounceTimeElapsed =  curTime - playerVC.lastBounceTime;
        
        if(bounceTimeElapsed < BOUNCE_TIME)
        {
            playerVC.newLocation = CGPointMake(playerVC.view.center.x - playerVC.moveVector.x, 
                                               playerVC.view.center.y - playerVC.moveVector.y);
        }
        else if(bounceTimeElapsed >= BOUNCE_TIME)
        {
            playerVC.isBounceActive = FALSE;
        }
    }
    
    
    playerVC.view.center = playerVC.newLocation;    
}

- (BOOL)isPointOutOfScreen:(CGPoint)screenPoint
{
    BOOL isOut = FALSE;
    
    if(screenPoint.y < 0 || screenPoint.y > 990 || screenPoint.x < 0 || screenPoint.x > 768)
    {
        isOut = TRUE;
    }
    
    return isOut;
}

- (BOOL)isRectIntersectPlane:(CGRect)objectRect withType:(int)objectType
{   
    BOOL isIntersecting = FALSE;
    
    for(int i=0; i < NUM_PLAYER; i++)
    {
        PlayerViewController *playerVC = (PlayerViewController *)[self.playerMutArray objectAtIndex:i];
        
        //redefine hit area
        CGRect hitAreaRect = CGRectMake(playerVC.view.frame.origin.x + playerVC.hitAreaView.frame.origin.x, 
                                        playerVC.view.frame.origin.y + playerVC.hitAreaView.frame.origin.y, 
                                        playerVC.hitAreaView.frame.size.width, 
                                        playerVC.hitAreaView.frame.size.height);
        
        if(CGRectIntersectsRect(hitAreaRect, objectRect))
        {
            //object intersects with plane       
            isIntersecting = TRUE;
            
            if(objectType == OBJECT_TYPE_LASER)
            {
                NSLog(@"player: %d got hit by laser", i);
                
                float curProgress = playerVC.healthProgressView.progress;
                
                curProgress -= (float)0.2;
                
                [playerVC.healthProgressView setProgress:curProgress]; 
                
                //set score on the other plane
                
                PlayerViewController *playerVCOther = (PlayerViewController *)[self.playerMutArray objectAtIndex:((NUM_PLAYER-1) - i)];
                playerVCOther.score += SCORE_LASER_HIT_PLANE;
                
                
                int curPlayerIdx = (NUM_PLAYER - 1) - i;
                
                if(curPlayerIdx == 0)
                {
                    self.p1ScoreLabel.text = [NSString stringWithFormat:@"%03d", playerVCOther.score];
                }
                else if(curPlayerIdx == 1)
                {
                    self.p2ScoreLabel.text = [NSString stringWithFormat:@"%03d", playerVCOther.score];
                }
                
            }
            else if(objectType == OBJECT_TYPE_ROCKET)
            {
                NSLog(@"player: %d got hit by ROCKET", i);
                
                float curProgress = playerVC.healthProgressView.progress;
                
                curProgress -= (float)0.4;
                
                [playerVC.healthProgressView setProgress:curProgress];
                
                
                //set score on the other plane
                
                PlayerViewController *playerVCOther = (PlayerViewController *)[self.playerMutArray objectAtIndex:((NUM_PLAYER-1) - i)];
                playerVCOther.score += SCORE_ROCKET_HIT_PLANE;
                
                
                int curPlayerIdx = (NUM_PLAYER - 1) - i;
                
                if(curPlayerIdx == 0)
                {
                    self.p1ScoreLabel.text = [NSString stringWithFormat:@"%03d", playerVCOther.score];
                }
                else if(curPlayerIdx == 1)
                {
                    self.p2ScoreLabel.text = [NSString stringWithFormat:@"%03d", playerVCOther.score];
                }   
            }
            else if(objectType == OBJECT_TYPE_ROCKET_COLLECTIBLE)
            {
                [playerVC addOneRocket];
            }
            else if(objectType == OBJECT_TYPE_ASTEROID)
            {
                playerVC.healthProgressView.progress -= 0.1;
            }
            
            
            if(playerVC.healthProgressView.progress <= 0.0)
            {
                UIColor *blackOverlayColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
                
                if(self.winningScreenView.superview == nil)
                {
                    int winnerIdx = (NUM_PLAYER-1) - i;
                    self.winnerLabel.text = [NSString stringWithFormat:@"P%d Wins !", winnerIdx + 1];
                    
                    [self.view addSubview:self.winningScreenView];
                    
                    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^(void) {
                        
                        self.winningScreenView.backgroundColor = blackOverlayColor;
                        
                    } completion:^(BOOL finished) {
                        
                    }];
                }
            }
            
            
            break;
        }
    }
    
    return isIntersecting;
}

- (void) explodeOnPoint:(CGPoint)explodePoint
{
    ///create explosion
    UIImage *explosionSprite = [UIImage imageNamed:@"explosion3.png"];
    NSMutableArray *expImgFrameMutArray = [[NSMutableArray alloc] init];
    
    for (int i=0; i < 4; i++) {
        
        CGRect cropRect = CGRectMake(150 * i, 0, 150, 115);
        CGImageRef imageRef = CGImageCreateWithImageInRect(explosionSprite.CGImage, cropRect);
        UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:explosionSprite.imageOrientation];
        
        [expImgFrameMutArray addObject:newImage];
        
        CGImageRelease(imageRef);
    }
    
    [self.explosionSoundPlayer play];
    
    CGRect explosionFrame = CGRectMake(explodePoint.x - 0.5 * 150, (explodePoint.y - 0.5 * 115) + 10, 150, 115);
    UIImageView *explosionImgView = [[UIImageView alloc] initWithFrame:explosionFrame];
    explosionImgView.animationImages = expImgFrameMutArray;
    explosionImgView.animationDuration = 1.0;
    explosionImgView.animationRepeatCount = 1;
    [explosionImgView startAnimating];
    
    //add to the scene
    [self.view addSubview:explosionImgView];
    
    
    [explosionImgView release];//release imgView
    [expImgFrameMutArray release];//release frame array    
}

- (float)calcDistanceWithPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2
{
    float dist = 0.0;
    
    float x2Minx1 = point2.x - point1.x;
    float y2Miny1 = point2.y - point1.y;
    
    dist = sqrtf(x2Minx1 * x2Minx1 + y2Miny1 * y2Miny1);
    
    return dist;
}


//=== touches delegates

/*
 - (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
 {    
 for (int i=0; i < [touches count]; i++) {
 
 UITouch *touch = (UITouch *)[[touches allObjects] objectAtIndex:i];
 CGPoint touchPoint = [touch locationInView:self.view];
 
 if (CGRectContainsPoint(self.joyPad1.frame, touchPoint))
 {
 isJoypad1Pressed = true;
 
 joyPad1DeltaTouch.x = touchPoint.x - self.joyPad1Base.center.x;
 joyPad1DeltaTouch.y = touchPoint.y - self.joyPad1Base.center.y;
 }
 
 if(CGRectContainsPoint(self.joyPad2.frame, touchPoint))
 {
 isJoypad2Pressed = true;
 
 joyPad2DeltaTouch.x = touchPoint.x - self.joyPad2Base.center.x;
 joyPad2DeltaTouch.y = touchPoint.y - self.joyPad2Base.center.y;
 }        
 }
 }
 
 - (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
 {
 for (int i=0; i < [touches count]; i++) {
 
 UITouch *touch = (UITouch *)[[touches allObjects] objectAtIndex:i];
 CGPoint touchPoint = [touch locationInView:self.view];
 
 float maxRadius = 84.0;
 float maxRadiusAllowedOutSide = 170.0;    
 
 if(isJoypad1Pressed)
 {           
 float dx = self.joyPad1Base.center.x - touchPoint.x;
 float dy = self.joyPad1Base.center.y - touchPoint.y;
 
 _TOUCH_DISTANCE_JOYPAD1 = [self calcDistanceWithPoint1:self.joyPad1Base.center andPoint2:touchPoint];
 
 _TOUCH_ANGLE_JOYPAD1 = atan2(dy, dx);
 
 
 if(_TOUCH_DISTANCE_JOYPAD1 > maxRadius && _TOUCH_DISTANCE_JOYPAD1 < maxRadiusAllowedOutSide)
 {  
 
 self.joyPad1.center = CGPointMake(self.joyPad1Base.center.x - cosf(_TOUCH_ANGLE_JOYPAD1) * maxRadius, 
 self.joyPad1Base.center.y - sinf(_TOUCH_ANGLE_JOYPAD1) * maxRadius);
 
 }
 else if(_TOUCH_DISTANCE_JOYPAD1 >= maxRadiusAllowedOutSide)
 {
 [self touchesEnded:touches withEvent:event];
 }
 else
 {
 self.joyPad1.center = CGPointMake(touchPoint.x - joyPad1DeltaTouch.x, 
 touchPoint.y - joyPad1DeltaTouch.y);
 }
 }
 
 if(isJoypad2Pressed)
 {
 float dx = self.joyPad2Base.center.x - touchPoint.x;
 float dy = self.joyPad2Base.center.y - touchPoint.y;
 
 _TOUCH_DISTANCE_JOYPAD2 = [self calcDistanceWithPoint1:self.joyPad2Base.center andPoint2:touchPoint];
 
 _TOUCH_ANGLE_JOYPAD2 = atan2(dy, dx);
 
 
 if(_TOUCH_ANGLE_JOYPAD2 > maxRadius && _TOUCH_DISTANCE_JOYPAD2 < maxRadiusAllowedOutSide)
 {
 self.joyPad2.center = CGPointMake(self.joyPad2Base.center.x - cosf(_TOUCH_ANGLE_JOYPAD2) * maxRadius, 
 self.joyPad2Base.center.y - sinf(_TOUCH_ANGLE_JOYPAD2) * maxRadius);
 }
 else if(_TOUCH_DISTANCE_JOYPAD2 >= maxRadiusAllowedOutSide)
 {
 [self touchesMoved:touches withEvent:event];
 }
 else
 {
 self.joyPad2.center = CGPointMake(touchPoint.x - joyPad2DeltaTouch.x, 
 touchPoint.y - joyPad2DeltaTouch.y);
 }
 }
 }
 }
 
 - (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
 {
 if(isJoypad1Pressed)
 {
 isJoypad1Pressed = false;
 
 //animation block
 [UIView beginAnimations:@"Joypad back to position" context:NULL];
 [UIView setAnimationBeginsFromCurrentState:YES];
 [UIView setAnimationDuration:0.3];
 [UIView setAnimationDelay:UIViewAnimationCurveEaseInOut];
 
 self.joyPad1.center = self.joyPad1Base.center;
 
 [UIView commitAnimations];
 }
 
 if(isJoypad2Pressed)
 {
 isJoypad2Pressed = false;
 
 //animation block
 [UIView beginAnimations:@"Joypad back to position" context:NULL];
 [UIView setAnimationBeginsFromCurrentState:YES];
 [UIView setAnimationDuration:0.3];
 [UIView setAnimationDelay:UIViewAnimationCurveEaseInOut];
 
 self.joyPad2.center = self.joyPad2Base.center;
 
 [UIView commitAnimations];       
 }
 }
 */

- (IBAction)btn1FirePressed:(id)sender
{        
    //get the first player
    PlayerViewController *player1 = (PlayerViewController *)[self.playerMutArray objectAtIndex:PLAYER_1_IDX];
    
    //initialize laser
    LaserViewController *laserVC = [[LaserViewController alloc] 
                                    initWithNibName:@"LaserViewController" bundle:nil];   
    
    laserVC.view.center = CGPointMake(player1.view.center.x, player1.view.frame.origin.y - 30);
    laserVC.moveVector = CGPointMake(0, -1);
    
    [self.laserMutArray addObject:laserVC];
    
    //play sound
    [self.laserSoundPlayer play];  
    
    [laserVC release];
}

- (IBAction)btn1_AltFirePressed:(id)sender
{
    //get the first player
    PlayerViewController *player1 = (PlayerViewController *)[self.playerMutArray objectAtIndex:PLAYER_1_IDX];
    
    //initialize laser
    
    if(player1.rocketCount > 0)
    {
        RocketViewController *rocketVC = [[RocketViewController alloc] 
                                          initWithNibName:@"RocketViewController" bundle:nil];   
        
        rocketVC.view.center = CGPointMake(player1.view.center.x, player1.view.frame.origin.y - 30);
        rocketVC.moveVector = CGPointMake(0, -1);
        
        [self.rocketMutArray addObject:rocketVC];
        
        //play sound
        //play rocket sound here....
        
        [rocketVC release];
        
        
        player1.rocketCount--;
        [player1 updateRocketCount];
    }
}

- (IBAction)btn2FirePressed:(id)sender
{    
    //get the second player
    PlayerViewController *player2 = (PlayerViewController *)[self.playerMutArray objectAtIndex:PLAYER_2_IDX];
    
    //initialize laser
    LaserViewController *laserVC = [[LaserViewController alloc] 
                                    initWithNibName:@"LaserViewController" bundle:nil]; 
    
    laserVC.view.center = CGPointMake(player2.view.center.x, player2.view.frame.origin.y + 230);
    laserVC.moveVector = CGPointMake(0, 1);
    
    [self.laserMutArray addObject:laserVC];
    
    //play sound
    [self.laserSoundPlayer play];  
    
    [laserVC release];    
}

- (IBAction)btn2_AltFirePressed:(id)sender
{
    //get the second player
    PlayerViewController *player2 = (PlayerViewController *)[self.playerMutArray objectAtIndex:PLAYER_2_IDX];
    
    
    if(player2.rocketCount > 0)
    {
        //initialize laser
        RocketViewController *rocketVC = [[RocketViewController alloc] 
                                          initWithNibName:@"RocketViewController" bundle:nil];   
        
        rocketVC.view.center = CGPointMake(player2.view.center.x, player2.view.frame.origin.y + 230);
        rocketVC.moveVector = CGPointMake(0, 1);
        
        [self.rocketMutArray addObject:rocketVC];
        
        //play sound
        //play rocket sound here....
        
        [rocketVC release];  
        
        
        player2.rocketCount--;
        [player2 updateRocketCount];
    }
}

#pragma mark - Gesture recognizer handlers


CGPoint touchDelta;
BOOL isJoypadWithinBounds = YES;

- (void)handlePanGesture:(UIPanGestureRecognizer *) sender
{
    CGPoint touchPoint = [sender locationInView:self.view];  
    
    if(sender.view == self.joyPad1)
    {   
        isJoypad1Pressed = YES;
        
        if(sender.state == UIGestureRecognizerStateBegan)
        {
            isJoypadWithinBounds = YES;
            
            touchDelta = CGPointMake(touchPoint.x - self.joyPad1Base.center.x, 
                                     touchPoint.y - self.joyPad1Base.center.y);
        }      
        
        float dx = self.joyPad1Base.center.x - touchPoint.x;
        float dy = self.joyPad1Base.center.y - touchPoint.y;
        
        _TOUCH_DISTANCE_JOYPAD1 = [self calcDistanceWithPoint1:self.joyPad1Base.center andPoint2:touchPoint];
        
        _TOUCH_ANGLE_JOYPAD1 = atan2(dy, dx);  
        
        
        if(_TOUCH_DISTANCE_JOYPAD1 > maxRadius && _TOUCH_DISTANCE_JOYPAD1 < maxRadiusAllowedOutSide)
        {  
            
            self.joyPad1.center = CGPointMake(self.joyPad1Base.center.x - cosf(_TOUCH_ANGLE_JOYPAD1) * maxRadius, 
                                              self.joyPad1Base.center.y - sinf(_TOUCH_ANGLE_JOYPAD1) * maxRadius);
        }
        else if(_TOUCH_DISTANCE_JOYPAD1 >= maxRadiusAllowedOutSide)
        {
            isJoypadWithinBounds = NO;
        }
        else
        {
            self.joyPad1.center = CGPointMake(touchPoint.x - touchDelta.x, 
                                              touchPoint.y - touchDelta.y);
        }   
    }
    else if(sender.view == self.joyPad2)
    {
        isJoypad2Pressed = YES;
        
        if(sender.state == UIGestureRecognizerStateBegan)
        {
            isJoypadWithinBounds = YES;
            
            touchDelta = CGPointMake(touchPoint.x - self.joyPad2Base.center.x, 
                                     touchPoint.y - self.joyPad2Base.center.y);
        }      
        
        float dx = self.joyPad2Base.center.x - touchPoint.x;
        float dy = self.joyPad2Base.center.y - touchPoint.y;
        
        _TOUCH_DISTANCE_JOYPAD2 = [self calcDistanceWithPoint1:self.joyPad2Base.center andPoint2:touchPoint];
        
        _TOUCH_ANGLE_JOYPAD2 = atan2(dy, dx);  
        
        
        if(_TOUCH_DISTANCE_JOYPAD2 > maxRadius && _TOUCH_DISTANCE_JOYPAD2 < maxRadiusAllowedOutSide)
        {  
            
            self.joyPad2.center = CGPointMake(self.joyPad2Base.center.x - cosf(_TOUCH_ANGLE_JOYPAD2) * maxRadius, 
                                              self.joyPad2Base.center.y - sinf(_TOUCH_ANGLE_JOYPAD2) * maxRadius);
            
        }
        else if(_TOUCH_DISTANCE_JOYPAD2 >= maxRadiusAllowedOutSide)
        {
            isJoypadWithinBounds = NO;
        }
        else
        {
            self.joyPad2.center = CGPointMake(touchPoint.x - touchDelta.x, 
                                              touchPoint.y - touchDelta.y);
        }        
    }
    
    if(sender.state == UIGestureRecognizerStateEnded || ! isJoypadWithinBounds)
    {
        //=== bounce back
        
        [UIView animateWithDuration:0.5 
                              delay:0 
                            options:UIViewAnimationCurveEaseOut
                         animations:^{
                             
                             CGPoint pointOriCenter = CGPointZero;
                             
                             if(sender.view == self.joyPad1)
                             {
                                 isJoypad1Pressed = NO;
                                 
                                 pointOriCenter = self.joyPad1Base.center;
                             }
                             else if(sender.view == self.joyPad2)
                             {
                                 isJoypad2Pressed = NO;
                                 
                                 pointOriCenter = self.joyPad2Base.center;
                             }
                             
                             sender.view.center = pointOriCenter;  
                             
                         } 
                         completion:^(BOOL completion){
                             
                         }];          
    }
}

- (IBAction)restartBtnPressed:(id)sender
{
    self.winningScreenView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    [self.winningScreenView removeFromSuperview];
    
    //=== re-set player position, health and rocket count
    
    for(int i=0; i < NUM_PLAYER; i++)
    {
        PlayerViewController *playerVC = (PlayerViewController *)[self.playerMutArray objectAtIndex:i];
        
        CGPoint planeOrigin = CGPointZero;
        
        if(i == 0)
        {
            planeOrigin = CGPointMake(50, 600);
            
        }
        else if(i==1)
        {
            planeOrigin = CGPointMake(50, 210);
        }
        
        
        playerVC.view.frame = CGRectMake(planeOrigin.x, planeOrigin.y, 
                                         playerVC.view.frame.size.width, 
                                         playerVC.view.frame.size.height);  
        
        
        playerVC.view.center = CGPointMake(self.view.center.x, playerVC.view.center.y);
        
        
        playerVC.healthProgressView.progress = 1.0;
        playerVC.score = 0;
        playerVC.rocketCount = 3;
        [playerVC updateRocketCount];
    }
    
    
    //=== re-start game timers
    [self.gameTimer invalidate];
    [self.asteroidTimer invalidate];
    [self.rocketTimer invalidate];
    
    
    self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:1/30.0 target:self selector:@selector(mainGameLoop) userInfo:nil repeats:YES];
    
    self.asteroidTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(asteroidTimerCall) userInfo:nil repeats:YES];  
    
    self.rocketTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(rocketTimerCall) userInfo:nil repeats:YES];   
}

- (IBAction)quitAppBtnPressed:(id)sender
{
    exit(0);
}

- (IBAction)btnBTConnectPressed:(id)sender
{
    [self startBluetooth];
}

#pragma mark - Bluetooth delegates

- (void)startBluetooth
{
    /*peerPicker = [[GKPeerPickerController alloc] init];
    peerPicker.delegate = self;
    peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
    
    [peerPicker show];*/
    
    if(! self.currentSession)
    {
        NSString *deviceName = [[UIDevice currentDevice] name];
        
        GKSession *tempSession = [[GKSession alloc] initWithSessionID:kSessionID displayName:deviceName sessionMode:GKSessionModeServer];
        
        self.currentSession = tempSession;
        self.currentSession.delegate = self;
        self.currentSession.available = YES;
        self.currentSession.disconnectTimeout = 0;
        [self.currentSession setDataReceiveHandler:self withContext:nil];
        
        [tempSession release]; 
        
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Session started" message:@"Server Session started !" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alert show];
        [alert release];     
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Session running" message:[NSString stringWithFormat:@"Server session id %@ and sessionName %@ is running", self.currentSession.sessionID, self.currentSession.displayName] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alert show];
        [alert release];        
    }
    
}

- (void)peerPickerController:(GKPeerPickerController *)pk didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
{
    self.currentSession = session;
    self.currentSession.delegate = self;
    [self.currentSession setDataReceiveHandler:self withContext:nil];
    
    //add peerID to the mut array
    [self.peerIdMutArray addObject:peerID];
    
    //if([self.peerIdMutArray count] == 2)
    //{
        if(! IS_GAME_STARTED)
        {
            //start timers
            self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:1/30.0 target:self selector:@selector(mainGameLoop) userInfo:nil repeats:YES];
            
            self.asteroidTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(asteroidTimerCall) userInfo:nil repeats:YES];  
            
            self.rocketTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(rocketTimerCall) userInfo:nil repeats:YES];  
            
            
            IS_GAME_STARTED = TRUE;
        }
    //}
    
    NSLog(@"[in iPad] peer connected, my session mode: %d, session id:%@, session name:%@", session.sessionMode, session.sessionID, session.displayName);
    
    NSLog(@"[in iPad], newly connected peer id:%@, name:%@", peerID, [session displayNameForPeer:peerID]);
    
    if(self.currentSession)
    {   
        int playerIdx = [self.peerIdMutArray count];
        
        if(playerIdx == 1)
        {
            self.btConnectP1.hidden = YES;
        }
        else if(playerIdx == 2)
        {
            self.btConnectP2.hidden = YES;
        }

        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"FIRST_CONNECTED", @"TYPE",
                                  @"MASTER", @"ROLE",
                                  [NSNumber numberWithInt:playerIdx - 1], @"PLAYER_IDX",
                                  session.sessionID, @"peerID", nil];   
        
        NSError *error;
        NSString *jsonString = [self.sbJSON stringWithObject:dataDict error:&error];
        
        
        if (! jsonString)
        {
            NSLog(@"JSON creation failed: %@", [error localizedDescription]);
        }
        else
        {
            NSLog(@"json string to send out: %@", jsonString);
            
            NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSArray *iphoneTableArray = [NSArray arrayWithObject:peerID];//send the first data back to the newly connected peer
            
            [self.currentSession sendData:data toPeers:iphoneTableArray withDataMode:GKSendDataReliable error:nil];
        }     
    }
    else
    {
        NSLog(@"current BT session not available");
    }    
    
    peerPicker.delegate = nil;
    [peerPicker dismiss];
    [peerPicker autorelease];
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)pk
{
    peerPicker.delegate = nil;
    [peerPicker autorelease];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    NSString *peerDisplayName = [session displayNameForPeer:peerID];
    
    REMOTE_ATTEMPT_PEER_ID = peerID;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection request" message:[NSString stringWithFormat:@"Peer %@ requesting connection", peerDisplayName] delegate:self cancelButtonTitle:@"Accept" otherButtonTitles:@"Decline", nil];
    alert.tag = kALERT_CONNECT_CONFIRMATION;
    [alert show];
    [alert release];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    NSString *peerDisplayName = [session displayNameForPeer:peerID];
    
    switch (state) {
        case GKPeerStateConnected:
            NSLog(@"[in iPad] peer is connected");
            
            {
                //add peerID to the mut array
                if([self.peerIdMutArray count] < 2)
                {
                    [self.peerIdMutArray addObject:peerID];
                    
                    if([self.peerIdMutArray count] == 2)
                    {
                        if(! IS_GAME_STARTED)
                        {
                            //start timers
                            self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:1/30.0 target:self selector:@selector(mainGameLoop) userInfo:nil repeats:YES];
                            
                            self.asteroidTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(asteroidTimerCall) userInfo:nil repeats:YES];  
                            
                            self.rocketTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(rocketTimerCall) userInfo:nil repeats:YES];  
                            
                            
                            IS_GAME_STARTED = TRUE;
                        }
                    }
                                    
                    if(self.currentSession)
                    {   
                        int playerIdx = [self.peerIdMutArray count];
                        
                        if(playerIdx == 1)
                        {
                            self.btConnectP1.hidden = YES;
                        }
                        else if(playerIdx == 2)
                        {
                            self.btConnectP2.hidden = YES;
                        }
                        
                        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"FIRST_CONNECTED", @"TYPE",
                                                  @"MASTER", @"ROLE",
                                                  [NSNumber numberWithInt:playerIdx - 1], @"PLAYER_IDX",
                                                  session.sessionID, @"peerID", nil];   
                        
                        NSError *error;
                        NSString *jsonString = [self.sbJSON stringWithObject:dataDict error:&error];
                        
                        
                        if (! jsonString)
                        {
                            NSLog(@"JSON creation failed: %@", [error localizedDescription]);
                        }
                        else
                        {
                            NSLog(@"json string to send out: %@", jsonString);
                            
                            NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                            NSArray *iphoneTableArray = [NSArray arrayWithObject:peerID];//send the first data back to the newly connected peer
                            
                            [self.currentSession sendData:data toPeers:iphoneTableArray withDataMode:GKSendDataReliable error:nil];
                        }     
    
                    }
                }
            }
            
            break;
        case GKPeerStateDisconnected:
            NSLog(@"[in iPad] peer is DISconnected");
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnected" message:[NSString stringWithFormat:@"Peer %@ is disconnected", peerDisplayName] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            [alert release];     
            
            break;
        case GKPeerStateAvailable:
            NSLog(@"[in iPad] peer is available");
            break;
        case GKPeerStateUnavailable:
            NSLog(@"[in iPad] peer is UNavailable");
            break;
            
        default:
            break;
    }
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    NSLog(@"connection with peer %@ failed !", peerID);
    
    [self printOutDescriptionAndSolutionOfError:error];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    NSLog(@"fatal error");
    
    if(self.currentSession)
    {
        [self invalidateSession:self.currentSession];
        self.currentSession = nil;
    }
    
    [self printOutDescriptionAndSolutionOfError:error];    
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSError *error;
    NSDictionary *dataDictionary = [self.sbJSON objectWithString:dataStr error:&error];
    
    if(! dataDictionary)
    {
        NSLog(@"JSON parsing failed: %@", [error localizedDescription]);
    }
    else
    {
        NSLog(@"JSON parsing success");
        
        NSDictionary *objectDict = [sbJSON objectWithString:dataStr error:nil];
        
        NSString *type = [objectDict objectForKey:@"TYPE"];
        
        if([type isEqualToString:@"FIRST_CONNECTED"])
        {
            NSLog(@"first connected peer role: %@", [objectDict objectForKey:@"ROLE"]);
            NSLog(@"first connected peer id: %@", [objectDict objectForKey:@"peerID"]);
        }
        else if([type isEqualToString:@"MOVEMENT"])
        {
            /*
             json format:
             
             {
             type: MOVEMENT
             //role: CLIENT
             //peerID: <peerID string>
             touchDistance: <float value>
             touchAngle: <float value>
             }
             
             */
            
            NSNumber *curPlayer_Number = (NSNumber *)[objectDict objectForKey:@"CUR_PLAYER_IDX"];
            NSNumber *touchDistance_Number = (NSNumber *)[objectDict objectForKey:@"touchDistance"];
            NSNumber *touchAngle_Number = (NSNumber *)[objectDict objectForKey:@"touchAngle"];
            
            int curPlayerIdx = [curPlayer_Number intValue];
            
            NSLog(@"curPlayerIdx: %d", curPlayerIdx);
           
            if(curPlayerIdx == PLAYER_1_IDX)
            {
                isJoypad1Pressed = TRUE;
                
                _TOUCH_DISTANCE_JOYPAD1 = [touchDistance_Number floatValue];
                _TOUCH_ANGLE_JOYPAD1 = [touchAngle_Number floatValue];
            }
            
            if(curPlayerIdx == PLAYER_2_IDX)
            {
                isJoypad2Pressed = TRUE;
                
                _TOUCH_DISTANCE_JOYPAD2 = [touchDistance_Number floatValue];
                _TOUCH_ANGLE_JOYPAD2 = [touchAngle_Number floatValue];
            }
        }
        else if([type isEqualToString:@"STOP_MOVEMENT"])
        {
            NSNumber *curPlayer_Number = (NSNumber *)[objectDict objectForKey:@"CUR_PLAYER_IDX"];
            
            int curPlayerIdx = [curPlayer_Number intValue];
            
            if(curPlayerIdx == PLAYER_1_IDX)
            {
                isJoypad1Pressed = FALSE;
            }
            else if(curPlayerIdx == PLAYER_2_IDX)
            {
                isJoypad2Pressed = FALSE;
            }   
        }
        else if([type isEqualToString:@"FIRE"])
        {
            NSNumber *curPlayer_Number = (NSNumber *)[objectDict objectForKey:@"CUR_PLAYER_IDX"];
            NSNumber *btnTag_Number =  (NSNumber *)[objectDict objectForKey:@"FIRE_BTN_TAG"];
            int btnFireTag = [btnTag_Number intValue];
            
            int curPlayerIdx = [curPlayer_Number intValue];
            
            if(curPlayerIdx == PLAYER_1_IDX)
            {
                if(btnFireTag == 0)
                {
                    [self btn1FirePressed:nil];
                }
                else if(btnFireTag == 1)
                {
                    [self btn1_AltFirePressed:nil];
                }
            }
            else if(curPlayerIdx == PLAYER_2_IDX)
            {
                if(btnFireTag == 0)
                {
                    [self btn2FirePressed:nil];
                }
                else if(btnFireTag == 1)
                {
                    [self btn2_AltFirePressed:nil];
                }      
            }         
            
        }
    }
    
    [dataStr release];
}

#pragma mark - AlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == kALERT_CONNECT_CONFIRMATION)
    {
        if(buttonIndex == 0)
        {
            //Accept
            
            if(! [REMOTE_ATTEMPT_PEER_ID isEqualToString:@""] && self.currentSession)
            {
                NSError *error = nil;
                [self.currentSession acceptConnectionFromPeer:REMOTE_ATTEMPT_PEER_ID error:&error];
                
                if(error != nil)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error accepting connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                    [alert release];
                }
            }
        }
        else if(buttonIndex == 1)
        {
            //Decline
            
            if(! [REMOTE_ATTEMPT_PEER_ID isEqualToString:@""] && self.currentSession)
            {
                [self.currentSession denyConnectionFromPeer:REMOTE_ATTEMPT_PEER_ID];
            }         
        }
    }
}

#pragma mark - private method implementations

- (void)invalidateSession:(GKSession *)session {
    
	if(session != nil) {
        
        [session disconnectFromAllPeers]; 
		session.available = NO; 
		[session setDataReceiveHandler: nil withContext: NULL]; 
		session.delegate = nil; 
	}
}

- (void)printOutDescriptionAndSolutionOfError:(NSError *)error
{
    NSLog(@"================");
    
    NSLog(@"error code: %d", error.code);
    NSLog(@"description: %@", error.localizedDescription);
    NSLog(@"failure reason: %@", error.localizedFailureReason);
    
    NSLog(@"recovery options:");
    
    for(int i=0; i < error.localizedRecoveryOptions.count; i++)
    {
        NSLog(@"- %@", [error.localizedRecoveryOptions objectAtIndex:i]);
    }
    
    NSLog(@"recovery suggestion: %@", error.localizedRecoverySuggestion);
    
    NSLog(@"================");    
}

@end
