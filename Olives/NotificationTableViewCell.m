//
//  NotificationTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/12/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "NotificationTableViewCell.h"

@implementation NotificationTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.avatar.layer.cornerRadius = self.avatar.frame.size.width / 2;
    self.avatar.clipsToBounds = YES;
    self.avatar.layer.borderWidth = 1.0f;
    self.avatar.layer.borderColor = [UIColor whiteColor].CGColor;

    [self.backgroundCardView.layer setCornerRadius:5.0f];
    [self.backgroundCardView.layer setMasksToBounds:NO];


//    self.contentView.backgroundColor = [UIColor clearColor];
//    [self setBackgroundColor:[UIColor clearColor]];
    // set up for selected cell
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    [bgColorView.layer setCornerRadius:5.0f];
    [bgColorView.layer setMasksToBounds:NO];
    [bgColorView setBackgroundColor:[UIColor colorWithRed:143/255.0 green:225/255.0 blue: 247/255.0 alpha:0.5f]];


    [self setSelectedBackgroundView:bgColorView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
