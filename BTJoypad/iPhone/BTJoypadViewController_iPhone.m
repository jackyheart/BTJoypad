//
//  BTJoypadViewController_iPhone.m
//  BTJoypad
//
//  Created by sap_all\c5152815 on 9/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BTJoypadViewController_iPhone.h"

// GameKit Session ID for app
#define kSessionID @"BTJoypad"

#define kALERT_CONNECT_TO_MASTER_CONFIRMATION 0

@interface BTJoypadViewController_iPhone (private)

- (void)invalidateSession:(GKSession *)session;
- (void)printOutDescriptionAndSolutionOfError:(NSError *)error;

@end

@implementation BTJoypadViewController_iPhone

@synthesize joyPadBase;
@synthesize joyPad;
@synthesize playerInfoLbl;
@synthesize currentSession;
@synthesize peerIdMutArray;
@synthesize sbJSON;

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
    [joyPadBase release];
    [joyPad release];  
    [playerInfoLbl release];
    [currentSession release];
    [peerIdMutArray release];  
    [sbJSON release];
    
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
    
    //==== add gesture recognizer to the joypad
    UIPanGestureRecognizer *panRecognizer_joypad = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    
    [self.joyPad addGestureRecognizer:panRecognizer_joypad];
    
    [panRecognizer_joypad release];  
    
    
    //=== Initialize variables
    maxRadius = 84.0;
    maxRadiusAllowedOutSide = 170.0;  
    isJoypadWithinBounds = YES;
    isJoypadPressed = NO;
    CUR_PLAYER_IDX = 0;
    MASTER_PEER_ID = @"";
    
    //=== initialize SBJSON
    self.sbJSON = [[SBJSON alloc] init];
    self.sbJSON.humanReadable = YES;   
    
    //=== initialize peer ID mutable array
    self.peerIdMutArray = [NSMutableArray array];  
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
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Application logic

- (IBAction)btnFirePressed:(id)sender
{        
    //send out btn1 fire pressed
    [self sendFirePressedWithTag:0];
}

- (IBAction)btn_AltFirePressed:(id)sender
{
    //send out btn_altFire pressed
    [self sendFirePressedWithTag:1];
}

- (IBAction)connectBtnPressed:(id)sender
{
    [self startBluetooth];
}

#pragma mark - Util

- (float)calcDistanceWithPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2
{
    float dist = 0.0;
    
    float x2Minx1 = point2.x - point1.x;
    float y2Miny1 = point2.y - point1.y;
    
    dist = sqrtf(x2Minx1 * x2Minx1 + y2Miny1 * y2Miny1);
    
    return dist;
}

- (void)sendOutJoypadMovingStateWithTouchDistance:(float)touchDistance andTouchAngle:(float)touchAngle
{
    if(self.currentSession)
    {
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"MOVEMENT", @"TYPE",
                                  [NSNumber numberWithInt:CUR_PLAYER_IDX], @"CUR_PLAYER_IDX",
                                  [NSNumber numberWithFloat:touchDistance], @"touchDistance",
                                  [NSNumber numberWithFloat:touchAngle], @"touchAngle", 
                                  nil];
        
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
            NSArray *ipadTableArray = (NSArray *)self.peerIdMutArray;
            
            [self.currentSession sendData:data toPeers:ipadTableArray withDataMode:GKSendDataReliable error:nil];
        }
    }
    else
    {
        NSLog(@"current BT session not available");
    }
}

- (void)sendOutJoypadStopState
{
    if(self.currentSession)
    {
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"STOP_MOVEMENT", @"TYPE",
                                  [NSNumber numberWithInt:CUR_PLAYER_IDX], @"CUR_PLAYER_IDX",
                                  nil];
        
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
            NSArray *ipadTableArray = (NSArray *)self.peerIdMutArray;
            
            [self.currentSession sendData:data toPeers:ipadTableArray withDataMode:GKSendDataReliable error:nil];
        }
    }
    else
    {
        NSLog(@"current BT session not available");
    }    
}

- (void)sendFirePressedWithTag:(int)btnTag
{
    if(self.currentSession)
    {
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"FIRE", @"TYPE",
                                  [NSNumber numberWithInt:CUR_PLAYER_IDX], @"CUR_PLAYER_IDX",
                                  [NSNumber numberWithInt:btnTag], @"FIRE_BTN_TAG",
                                  nil];
        
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
            NSArray *ipadTableArray = (NSArray *)self.peerIdMutArray;
            
            [self.currentSession sendData:data toPeers:ipadTableArray withDataMode:GKSendDataReliable error:nil];
        }
    }
    else
    {
        NSLog(@"current BT session not available");
    }     
}

#pragma mark - Gesture handlers

- (void)handlePanGesture:(UIPanGestureRecognizer *) sender
{
    CGPoint touchPoint = [sender locationInView:self.view];  
    
    if(sender.view == self.joyPad)
    {   
        isJoypadPressed = YES;
        
        if(sender.state == UIGestureRecognizerStateBegan)
        {
            isJoypadWithinBounds = YES;
            
            touchDelta = CGPointMake(touchPoint.x - self.joyPadBase.center.x, 
                                     touchPoint.y - self.joyPadBase.center.y);
        }      
        
        float dx = self.joyPadBase.center.x - touchPoint.x;
        float dy = self.joyPadBase.center.y - touchPoint.y;
        
        _TOUCH_DISTANCE_JOYPAD = [self calcDistanceWithPoint1:self.joyPadBase.center andPoint2:touchPoint];
        
        _TOUCH_ANGLE_JOYPAD = atan2(dy, dx);  
        
        if(_TOUCH_DISTANCE_JOYPAD > maxRadius && _TOUCH_DISTANCE_JOYPAD < maxRadiusAllowedOutSide)
        {  
            
            self.joyPad.center = CGPointMake(self.joyPadBase.center.x - cosf(_TOUCH_ANGLE_JOYPAD) * maxRadius, 
                                              self.joyPadBase.center.y - sinf(_TOUCH_ANGLE_JOYPAD) * maxRadius);
        }
        else if(_TOUCH_DISTANCE_JOYPAD >= maxRadiusAllowedOutSide)
        {
            isJoypadWithinBounds = NO;
        }
        else
        {
            self.joyPad.center = CGPointMake(touchPoint.x - touchDelta.x, 
                                              touchPoint.y - touchDelta.y);
        }   
        
        
        [self sendOutJoypadMovingStateWithTouchDistance:_TOUCH_DISTANCE_JOYPAD andTouchAngle:_TOUCH_ANGLE_JOYPAD];
    }
    
    if(sender.state == UIGestureRecognizerStateEnded || ! isJoypadWithinBounds)
    {
        [self sendOutJoypadStopState];
        
        //=== bounce back
        
        [UIView animateWithDuration:0.5 
                              delay:0 
                            options:UIViewAnimationCurveEaseOut
                         animations:^{
                             
                             CGPoint pointOriCenter = CGPointZero;
                             
                             if(sender.view == self.joyPad)
                             {
                                 isJoypadPressed = NO;
                                 
                                 pointOriCenter = self.joyPadBase.center;
                             }
                             
                             sender.view.center = pointOriCenter;  
                             
                         } 
                         completion:^(BOOL completion){
                             
                         }];          
    }
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
        
        GKSession *tempSession = [[GKSession alloc] initWithSessionID:kSessionID displayName:deviceName sessionMode:GKSessionModeClient];
        
        self.currentSession = tempSession;
        self.currentSession.delegate = self;
        self.currentSession.available = YES;
        self.currentSession.disconnectTimeout = 0;
        [self.currentSession setDataReceiveHandler:self withContext:nil];
        
        [tempSession release];   
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Session started" message:@"Client Session started !" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
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
    
    NSLog(@"[in iPhone] peer connected, my session mode: %d, session id:%@, session name:%@", session.sessionMode, session.sessionID, session.displayName);
    
    NSLog(@"[in iPhone], newly connected peer id:%@, name:%@", peerID, [session displayNameForPeer:peerID]);
    
    if(self.currentSession)
    {                  
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"FIRST_CONNECTED", @"TYPE",
                                  @"CLIENT", @"ROLE",
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

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    NSString *peerDisplayName = [session displayNameForPeer:peerID];
    
    switch (state) {
        case GKPeerStateConnected:
            NSLog(@"[in iPad] peer is connected");
          
            {
                //add peerID to the mut array
                if(self.peerIdMutArray.count == 0)
                {
                    [self.peerIdMutArray addObject:peerID]; 
                }
            }  
            
            break;
        case GKPeerStateDisconnected:
            NSLog(@"[in iPad] peer is DISconnected");
            break;
        case GKPeerStateAvailable:
            NSLog(@"[in iPad] peer is available");
            
            {
                MASTER_PEER_ID = peerID;
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server found" message:[NSString stringWithFormat:@"Connect to server %@ ?", peerDisplayName] delegate:self cancelButtonTitle:@"YES" otherButtonTitles:@"NO", nil];
                alert.tag = kALERT_CONNECT_TO_MASTER_CONFIRMATION;
                [alert show];
                [alert release];     
            }   
            
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
            
            
            NSNumber *playerIdxNumber = (NSNumber *)[objectDict objectForKey:@"PLAYER_IDX"];
            CUR_PLAYER_IDX = [playerIdxNumber intValue];
            self.playerInfoLbl.text = [NSString stringWithFormat:@"%d", CUR_PLAYER_IDX + 1];
        }
    }
    
    [dataStr release];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == kALERT_CONNECT_TO_MASTER_CONFIRMATION)
    {
        if(buttonIndex == 0)
        {
            //YES
            
            if(! [MASTER_PEER_ID isEqualToString:@""] && self.currentSession)
            {
                [self.currentSession connectToPeer:MASTER_PEER_ID withTimeout:0];
            }
        }
        else if(buttonIndex == 1)
        {
            //NO
            
            //do nothing
        }
    }
}


#pragma mark - private method implementation

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
