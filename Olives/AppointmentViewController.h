//
//  AppointmentViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 6/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VRGCalendarView.h"

@interface AppointmentViewController : UIViewController <VRGCalendarViewDelegate>
@property(assign,nonatomic) BOOL isShowNotification;
@end
