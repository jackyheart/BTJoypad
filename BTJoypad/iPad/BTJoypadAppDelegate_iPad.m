//
//  BTJoypadAppDelegate_iPad.m
//  BTJoypad
//
//  Created by sap_all\c5152815 on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BTJoypadAppDelegate_iPad.h"

@implementation BTJoypadAppDelegate_iPad

@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    self.window.rootViewController = (UIViewController *)viewController;
    
    return YES;
}

- (void)dealloc
{
    [viewController release];
    
	[super dealloc];
}

@end
