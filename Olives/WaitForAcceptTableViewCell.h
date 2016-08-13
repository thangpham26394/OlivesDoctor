//
//  WaitForAcceptTableViewCell.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/11/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WaitForAcceptTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIImageView *patientAvatar;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;


@end
