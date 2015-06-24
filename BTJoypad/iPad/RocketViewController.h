//
//  RocketViewController.h
//  Joypad
//
//  Created by sap_all\c5152815 on 7/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RocketViewController : UIViewController {
    
    CGPoint moveVector;
    float speed;    
}

@property (nonatomic, assign) CGPoint moveVector;
@property (nonatomic, assign) float speed;

@end
