//
//  BTJoypadViewController_iPhone.h
//  BTJoypad
//
//  Created by sap_all\c5152815 on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "SBJSON.h"

@interface BTJoypadViewController_iPhone : UIViewController
<GKSessionDelegate, GKPeerPickerControllerDelegate> {
  
@private
    float maxRadius;
    float maxRadiusAllowedOutSide;  
    CGPoint touchDelta;
    BOOL isJoypadWithinBounds;
    BOOL isJoypadPressed;
    CGPoint joyPadDeltaTouch;
    float _TOUCH_DISTANCE_JOYPAD;
    float _TOUCH_ANGLE_JOYPAD; 
    int CUR_PLAYER_IDX;
    
    //bluetooth
    GKSession *currentSession;
    GKPeerPickerController *peerPicker;
    NSMutableArray *peerIdMutArray;
    @private NSString *MASTER_PEER_ID;
    
    //JSON
    SBJSON *sbJSON;     
}

@property (nonatomic, retain) IBOutlet UIImageView *joyPadBase;
@property (nonatomic, retain) IBOutlet UIImageView *joyPad;
@property (nonatomic, retain) IBOutlet UILabel *playerInfoLbl;
@property (nonatomic, retain) GKSession *currentSession;
@property (nonatomic, retain) NSMutableArray *peerIdMutArray;
@property (nonatomic, retain) SBJSON *sbJSON;

- (IBAction)btnFirePressed:(id)sender;
- (IBAction)btn_AltFirePressed:(id)sender;
- (IBAction)connectBtnPressed:(id)sender;
- (float)calcDistanceWithPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2;//Util
- (void)startBluetooth;
- (void)sendOutJoypadMovingStateWithTouchDistance:(float)touchDistance andTouchAngle:(float)touchAngle;
- (void)sendOutJoypadStopState;
- (void)sendFirePressedWithTag:(int)btnTag;

@end
