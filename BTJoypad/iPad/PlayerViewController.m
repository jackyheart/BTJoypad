//
//  PlayerViewController.m
//  Joypad
//
//  Created by Jacky on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlayerViewController.h"


@implementation PlayerViewController

@synthesize planeImgView;
@synthesize healthProgressView;
@synthesize hitAreaView;
@synthesize isBounceActive;
@synthesize lastBounceTime;
@synthesize newLocation;
@synthesize moveVector;
@synthesize smoothMoveFactor;
@synthesize score;
@synthesize rocketCount;
@synthesize rocketCountLabel;

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
    [planeImgView release];
    [healthProgressView release];
    [hitAreaView release];
    [rocketCountLabel release];
    
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
    
    isBounceActive = FALSE;
    lastBounceTime = 0.0;
    
    score = 0;
    rocketCount = 3;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)updateRocketCount
{
    self.rocketCountLabel.text = [NSString stringWithFormat:@"x %d", rocketCount];
}

- (void)addOneRocket
{
    if(rocketCount < 3)
    {
        rocketCount++;
        
        [self updateRocketCount];
    }
}

@end
