//
//  ViewController.m
//  Peer Attitude
//
//  Created by Colin T Power on 2016-02-29.
//  Copyright © 2016 Colin Power. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <CoreMotion/CMSensorRecorder.h>

@interface ViewController ()
{
    BOOL connected;
    BOOL reciever;
    CGRect originalViewFrame;
    double xAcc, yAcc, zAcc, xRot, yRot, zRot;
}

@property (weak, nonatomic) IBOutlet UILabel *deviceMode;
@property (strong,nonatomic) CMMotionManager *manager;
@property (strong,nonatomic) CMSensorRecorder *recorder;

@property (weak, nonatomic) IBOutlet UILabel *xAcel;
@property (weak, nonatomic) IBOutlet UILabel *yAcel;
@property (weak, nonatomic) IBOutlet UILabel *zAcel;
@property (weak, nonatomic) IBOutlet UILabel *xGyro;
@property (weak, nonatomic) IBOutlet UILabel *yGyro;
@property (weak, nonatomic) IBOutlet UILabel *zGyro;

@property (weak, nonatomic) IBOutlet UIView *xAccelView;
@property (weak, nonatomic) IBOutlet UIView *yAccelView;
@property (weak, nonatomic) IBOutlet UIView *zAccelView;
@property (weak, nonatomic) IBOutlet UIView *xGyroView;
@property (weak, nonatomic) IBOutlet UIView *yGyroView;
@property (weak, nonatomic) IBOutlet UIView *zGyroView;
@property (weak, nonatomic) IBOutlet UIButton *browseButton;
@property (weak, nonatomic) IBOutlet UIButton *transmitButton;
@property (weak, nonatomic) IBOutlet UIButton *disconnectButton;

@property (nonatomic, retain) NSTimer *timer;


- (IBAction)transmitButtonTapped:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)browseButtonTapped:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)disconnectButtonTapped:(UIButton *)sender;
- (IBAction)recieveButtonTapped:(UIButton *)sender forEvent:(UIEvent *)event;



@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCAdvertiserAssistant *assistant;
@property (strong, nonatomic) MCBrowserViewController *browserVC;
- (void)setUIToNotConnectedState;
- (void)setUIToConnectedState;
- (void)resetView;

@end

@implementation ViewController

@synthesize xAccelView, yAccelView, zAccelView, xGyroView, yGyroView, zGyroView;
@synthesize session;
@synthesize timer;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    connected = NO;
    reciever = YES;
    self.deviceMode.text = @"Reciever";
    

    [self setUIToNotConnectedState];
    originalViewFrame = self.view.frame;


    // Prepare session
    MCPeerID *myPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    self.session = [[MCSession alloc] initWithPeer:myPeerID];
    self.session.delegate = self;
    
    // Start advertising
    self.assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:SERVICE_TYPE discoveryInfo:nil session:self.session];
    [self.assistant start];
    self.manager = [[CMMotionManager alloc] init];

    if (self.manager.deviceMotionAvailable == YES) {
        [self startMonitoringMotion];
    }
    else
        NSLog(@"Accelerometer or gyro unavailable!");

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1/2 target:self selector:@selector(getValues:) userInfo:nil repeats:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) getValues:(NSTimer *) timer {
    
    if (connected == NO || reciever == NO) {
        
        CMAcceleration acc = self.manager.accelerometerData.acceleration;
        CMRotationRate rot = self.manager.gyroData.rotationRate;
        xAcc = acc.x;
        yAcc = acc.y;
        zAcc = acc.z;
        xRot = rot.x;
        yRot = rot.y;
        zRot = rot.z;
        [self refreshUIWithMotionData];
    }
    
    if (connected == YES && reciever == NO) {
        NSArray *peerIDs = session.connectedPeers;
        //turn double data into one string with ^ as the seperator
        NSString *data = [NSString stringWithFormat:@"%f^%f^%f^%f^%f^%f", xAcc, yAcc, zAcc, xRot, yRot, zRot];
        [session sendData:[data dataUsingEncoding:NSASCIIStringEncoding] toPeers:peerIDs withMode:MCSessionSendDataUnreliable error:nil];

        NSLog(@"Motion data sent to peers");
    }
}

- (void)startMonitoringMotion {
    self.manager.deviceMotionUpdateInterval = 1.0/kMOTIONUPDATEINTERVAL;
    self.manager.accelerometerUpdateInterval = 1.0/kMOTIONUPDATEINTERVAL;
    self.manager.gyroUpdateInterval = 1.0/kMOTIONUPDATEINTERVAL;
    self.manager.showsDeviceMovementDisplay = YES;
    [self.manager startDeviceMotionUpdates];
    [self.manager startAccelerometerUpdates];
    [self.manager startGyroUpdates];
}

- (void)stopMonitoringMotion {
    [self.manager stopAccelerometerUpdates];
    [self.manager stopGyroUpdates];
}


- (void)updateBarGraphView:(UIView *)barGraph value:(double)value scale:(double)scale {
    CGRect change;
    if (ABS(value*scale) < 10) //filters background noise
        change = CGRectMake(145, barGraph.frame.origin.y, 0, 20);
    else 
        change = CGRectMake(145, barGraph.frame.origin.y, value*scale, 20);
    [barGraph setFrame:(change)];
}

- (NSString *)participantID {
    return self.session.myPeerID.displayName;
}


- (IBAction)browseButtonTapped:(UIButton *)sender forEvent:(UIEvent *)event {
    self.browserVC = [[MCBrowserViewController alloc] initWithServiceType:SERVICE_TYPE session:self.session];
    self.browserVC.maximumNumberOfPeers = 2;
    self.browserVC.delegate = self;
    [self presentViewController:self.browserVC animated:YES completion:nil];
}


- (IBAction)transmitButtonTapped:(UIButton *)sender forEvent:(UIEvent *)event {
    NSLog(@"Device Set To Transmit");
        self.deviceMode.text = @"Transmitter";
        reciever = NO;
}

- (IBAction)recieveButtonTapped:(UIButton *)sender forEvent:(UIEvent *)event {
    NSLog(@"Device Set To Recieve");
    self.deviceMode.text = @"Reciever";
    reciever = YES;
}

- (IBAction)disconnectButtonTapped:(UIButton *)sender {
    [self setUIToNotConnectedState];
    [self.session disconnect];
    connected = NO;
}


#pragma mark
#pragma mark <MCSessionDelegate> methods
// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
    if (state == MCSessionStateConnected) {
        [self setUIToConnectedState];
        connected = YES;
        NSLog(@"Connection Made");
    }
    else if (state == MCSessionStateNotConnected) {
        [self setUIToNotConnectedState];
        connected = NO;
        NSLog(@"Connection Stopped");
    }
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    if (reciever == NO)
        return;
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSArray *values = [str componentsSeparatedByString:@"^"];
    NSString *strData = [NSString stringWithFormat:@"%@", values[0]];
    
    xAcc = [strData doubleValue];
    strData = [NSString stringWithFormat:@"%@", values[1]];
    yAcc = [strData doubleValue];
    strData = [NSString stringWithFormat:@"%@", values[2]];
    zAcc = [strData doubleValue];
    strData = [NSString stringWithFormat:@"%@", values[3]];
    xRot = [strData doubleValue];
    strData = [NSString stringWithFormat:@"%@", values[4]];
    yRot = [strData doubleValue];
    strData = [NSString stringWithFormat:@"%@", values[5]];
    zRot = [strData doubleValue];
    
    // asynchronously updates using recieved data
   dispatch_async(dispatch_get_main_queue(), ^{ [self refreshUIWithMotionData]; });
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {

}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {

}

#pragma mark
#pragma mark <MCBrowserViewControllerDelegate> methods
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark
#pragma mark helpers
- (void)setUIToNotConnectedState {
    self.transmitButton.enabled = YES;
    self.disconnectButton.enabled = NO;
    self.browseButton.enabled = YES;
}

- (void)setUIToConnectedState {
    self.transmitButton.enabled = YES;
    self.disconnectButton.enabled = YES;
    self.browseButton.enabled = NO;
}

- (void)setUIToNotRecieverState {
    //self.transmitButton.enabled = YES;
    //reciever = NO;
}

- (void)setUIToRecieverState {
    //self.transmitButton.enabled = NO;
   // reciever = NO;
}

- (void)resetView {
    self.view.frame = originalViewFrame;
}

- (void) refreshUIWithMotionData {
    [self updateBarGraphView:xAccelView value:xAcc scale:100];
    [self updateBarGraphView:yAccelView value:yAcc scale:100];
    [self updateBarGraphView:zAccelView value:zAcc scale:100];
    [self updateBarGraphView:xGyroView value:xRot scale:50];
    [self updateBarGraphView:yGyroView value:yRot scale:50];
    [self updateBarGraphView:zGyroView value:zRot scale:50];
    self.xAcel.text = [NSString stringWithFormat:@"%.1f",xAcc];
    self.yAcel.text = [NSString stringWithFormat:@"%.1f",yAcc];
    self.zAcel.text = [NSString stringWithFormat:@"%.1f",zAcc];
    self.xGyro.text = [NSString stringWithFormat:@"%.1f",xRot];
    self.yGyro.text = [NSString stringWithFormat:@"%.1f",yRot];
    self.zGyro.text = [NSString stringWithFormat:@"%.1f",zRot];
}


@end
