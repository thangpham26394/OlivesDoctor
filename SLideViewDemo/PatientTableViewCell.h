//
//  PatientTableViewCell.h
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 5/27/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PatientTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *backgroundCardView;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *address;

@end
