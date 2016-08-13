//
//  NotificationTableViewCell.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/12/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *backgroundCardView;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *notificationMessage;
@property (weak, nonatomic) IBOutlet UILabel *notificationCreatedTime;

@end
