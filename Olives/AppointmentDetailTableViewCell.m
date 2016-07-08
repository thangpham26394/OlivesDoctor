//
//  AppointmentDetailTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "AppointmentDetailTableViewCell.h"

@implementation AppointmentDetailTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.contentView.backgroundColor = [UIColor clearColor];
    [self setBackgroundColor:[UIColor clearColor]];
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width/2;
    self.avatarImage.clipsToBounds = YES;
    [self.backgroundCardView.layer setCornerRadius:10.0f];
    [self.backgroundCardView.layer setMasksToBounds:NO];
    [self.backgroundCardView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.7]];
    self.backgroundCardView.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.1] CGColor];
    self.backgroundCardView.layer.borderWidth = 5.0f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
