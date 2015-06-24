//
//  PlayerViewController.h
//  Joypad
//
//  Created by Jacky on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PlayerViewController : UIViewController {

    IBOutlet UIImageView *planeImgView;
    IBOutlet UIProgressView *healthProgressView;
    IBOutlet UIView *hitAreaView;
    
    BOOL isBounceActive;
    double lastBounceTime;
    
    //for updating location and speed
    CGPoint newLocation;
    CGPoint moveVector;
    float smoothMoveFactor;
    int score;
    int rocketCount;
    
    IBOutlet UILabel *rocketCountLabel;
}

@property (nonatomic, retain) UIImageView *planeImgView;
@property (nonatomic, retain) UIProgressView *healthProgressView;
@property (nonatomic, retain) UIView *hitAreaView;
@property (nonatomic, assign) BOOL isBounceActive;
@property (nonatomic, assign) double lastBounceTime;
@property (nonatomic, assign) CGPoint newLocation;
@property (nonatomic, assign) CGPoint moveVector;
@property (nonatomic, assign) float smoothMoveFactor;
@property (nonatomic, assign) int score;
@property (nonatomic, assign) int rocketCount;
@property (nonatomic, retain) UILabel *rocketCountLabel;

- (void)updateRocketCount;
- (void)addOneRocket;

@end
