//
//  AsteroidViewController.h
//  Joypad
//
//  Created by Jacky on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AsteroidViewController : UIViewController {
    
    CGPoint centerStartPoint;
    int positionType;//0=left; 1=right
}

@property (nonatomic, assign) CGPoint centerStartPoint;
@property (nonatomic, assign) int positionType;

@end
