//
//  ChatViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/15/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatViewController : UIViewController
@property(strong,nonatomic) NSString *selectedPatientID;
@property(strong,nonatomic) NSArray *unseenMessage;
@end
