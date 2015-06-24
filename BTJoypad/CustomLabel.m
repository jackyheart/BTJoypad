//
//  CustomLabel.m
//  Joypad
//
//  Created by sap_all\c5152815 on 7/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CustomLabel.h"


@implementation CustomLabel

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self == [super initWithCoder: aDecoder]) {
        [self setFont: [UIFont fontWithName: @"BadaBoom BB" size: self.font.pointSize]];
    }    
    
    return self;
}

@end
