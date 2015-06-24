//
//  BTJoypadViewController_iPad.h
//  BTJoypad
//
//  Created by sap_all\c5152815 on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <GameKit/GameKit.h>
#import "SBJSON.h"

#define CLAMP(X, A, B) ((X < A) ? A : ((X > B) ? B : X))

// MACROS
#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) * M_PI / 180.0)
#define RADIANS_TO_DEGREES(__ANGLE__) ((__ANGLE__) * 180 / M_PI)


@interface BTJoypadViewController_iPad : UIViewController 
<GKSessionDelegate, GKPeerPickerControllerDelegate> {
    
    //configuration variables
    @private float maxRadius;
    @private float maxRadiusAllowedOutSide;  
    @private CGPoint touchDelta;
    @private BOOL isJoypadWithinBounds;  
    
    //joypad 1 vars
    @private BOOL isJoypad1Pressed;
    @private CGPoint joyPad1DeltaTouch;
    @private float _TOUCH_DISTANCE_JOYPAD1;
    @private float _TOUCH_ANGLE_JOYPAD1;

    //joypad 2 vars
    @private BOOL isJoypad2Pressed;
    @private CGPoint joyPad2DeltaTouch;
    @private float _TOUCH_DISTANCE_JOYPAD2;
    @private float _TOUCH_ANGLE_JOYPAD2;  

    //SFX
    @private AVAudioPlayer *laserSoundPlayer;
    @private AVAudioPlayer *explosionSoundPlayer;

    //timer
    @private double lastTime;
    @private CGPoint _LAST_PLANE_CENTER_IN_SCREEN;   
    @private NSTimer *gameTimer;
    @private NSTimer *asteroidTimer;
    @private NSTimer *rocketTimer;
    @private double lastRocketTime;

    //flag
    @private BOOL SHOULD_GENERATE_ASTEROID;
    @private BOOL IS_GAME_STARTED;

    //holder arrays
    @private NSMutableArray *playerMutArray;
    @private NSMutableArray *laserMutArray;//Laser mutable arrays (for holding all lasers in the screen)
    @private NSMutableArray *rocketMutArray;//Rocket mutable arrays (holds all rockets in the screen)
    @private NSMutableArray *asteroidMutArray;//hold all asteroids on the screen

    //outlets
    IBOutlet UIImageView *joyPad1Base;
    IBOutlet UIImageView *joyPad1;
    IBOutlet UIImageView *joyPad2Base;
    IBOutlet UIImageView *joyPad2;
    IBOutlet UILabel *p1ScoreLabel;
    IBOutlet UILabel *p2ScoreLabel;

    //score label holders
    IBOutlet UIView *p1ScoreView;
    IBOutlet UIView *p2ScoreView;

    IBOutlet UIImageView *rocketImgView;
    @private CGPoint ROCKET_MOVE_VECTOR;
    @private float ROCKET_SPEED;

    //background
    IBOutlet UIImageView *backgroundImgView;
    IBOutlet UIImageView *backgroundDuplicateImgView;
    @private UIImageView *backgroundRefImgView;

    //bluetooth
    @private GKSession *currentSession;
    @private GKPeerPickerController *peerPicker;
    @private NSMutableArray *peerIdMutArray;
    @private NSString *REMOTE_ATTEMPT_PEER_ID;

    //JSON
    @private SBJSON *sbJSON;   


    //winning screen
    IBOutlet UIView *winningScreenView;
    IBOutlet UILabel *winnerLabel;    
    
    
    //connect btn
    IBOutlet UIButton *btConnectP1;
    IBOutlet UIButton *btConnectP2;
}

@property (nonatomic, retain) NSMutableArray *playerMutArray;
@property (nonatomic, retain) NSMutableArray *laserMutArray;
@property (nonatomic, retain) NSMutableArray *rocketMutArray;
@property (nonatomic, retain) NSMutableArray *asteroidMutArray;
@property (nonatomic, retain) AVAudioPlayer *laserSoundPlayer;
@property (nonatomic, retain) AVAudioPlayer *explosionSoundPlayer;
@property (nonatomic, retain) NSTimer *gameTimer;
@property (nonatomic, retain) NSTimer *asteroidTimer;
@property (nonatomic, retain) NSTimer *rocketTimer;
@property (nonatomic, retain) UIImageView *joyPad1Base;
@property (nonatomic, retain) UIImageView *joyPad1;
@property (nonatomic, retain) UIImageView *joyPad2Base;
@property (nonatomic, retain) UIImageView *joyPad2;
@property (nonatomic, retain) UILabel *p1ScoreLabel;
@property (nonatomic, retain) UILabel *p2ScoreLabel;
@property (nonatomic, retain) UIView *p1ScoreView;
@property (nonatomic, retain) UIView *p2ScoreView;
@property (nonatomic, retain) UIImageView *rocketImgView;
@property (nonatomic, retain) UIImageView *backgroundImgView;
@property (nonatomic, retain) UIImageView *backgroundDuplicateImgView;
@property (nonatomic, retain) UIImageView *backgroundRefImgView;
@property (nonatomic, retain) GKSession *currentSession;
@property (nonatomic, retain) NSMutableArray *peerIdMutArray;
@property (nonatomic, retain) SBJSON *sbJSON;
@property (nonatomic, retain) UIView *winningScreenView;
@property (nonatomic, retain) UILabel *winnerLabel;
@property (nonatomic, retain) UIButton *btConnectP1;
@property (nonatomic, retain) UIButton *btConnectP2;


- (void)updatePlayerWithIndex:(int)playerIdx;
- (BOOL)isPointOutOfScreen:(CGPoint)screenPoint;
- (BOOL)isRectIntersectPlane:(CGRect)objectRect withType:(int)objectType;
- (void) explodeOnPoint:(CGPoint)explodePoint;
- (float)calcDistanceWithPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2;
- (IBAction)btn1FirePressed:(id)sender;
- (IBAction)btn1_AltFirePressed:(id)sender;
- (IBAction)btn2FirePressed:(id)sender;
- (IBAction)btn2_AltFirePressed:(id)sender;
- (IBAction)restartBtnPressed:(id)sender;
- (IBAction)quitAppBtnPressed:(id)sender;
- (void)startBluetooth;
- (IBAction)btnBTConnectPressed:(id)sender;

@end
