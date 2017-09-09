//
//  ViewController.h
//  Peer Attitude
//
//  Created by Colin T Power on 2016-02-29.
//  Copyright © 2016 Colin Power. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#define SERVICE_TYPE @"mun4768-mcdemo"

#define kMOTIONUPDATEINTERVAL 2

@interface ViewController : UIViewController <MCSessionDelegate, MCBrowserViewControllerDelegate>

@end

