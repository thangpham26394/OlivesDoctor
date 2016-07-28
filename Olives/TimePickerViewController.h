//
//  TimePickerViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/12/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimePickerViewController : UIViewController
@property(strong,nonatomic) NSString *chosenDate;
@property(strong,nonatomic) NSDictionary *selectedPatient;
@property(strong,nonatomic) NSString *appointmentID;
@property(strong,nonatomic) NSString *segmentUsing;
@property(assign,nonatomic) BOOL isActiveAppointment;
@end
