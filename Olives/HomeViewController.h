//
//  HomeViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 6/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *badgeAppointmentLabel;
@property (weak, nonatomic) IBOutlet UILabel *badgeMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *badgeMedicalRecordLabel;
@property (weak, nonatomic) IBOutlet UILabel *badgeRequestLabel;

@end
