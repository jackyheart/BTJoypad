//
//  LaserViewController.h
//  Joypad
//
//  Created by Jacky on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LaserViewController : UIViewController {
 
    IBOutlet UIImageView *laserImgView;
    CGPoint moveVector;
    float speed;
}

@property (nonatomic, retain) UIImageView *laserImgView;
@property (nonatomic, assign) CGPoint moveVector;
@property (nonatomic, assign) float speed;

@end
