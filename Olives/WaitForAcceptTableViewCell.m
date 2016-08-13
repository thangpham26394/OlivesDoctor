//
//  WaitForAcceptTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/11/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "WaitForAcceptTableViewCell.h"

@implementation WaitForAcceptTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.cancelButton.layer.cornerRadius = 5.0f;
    self.acceptButton.layer.cornerRadius = 5.0f;
    self.patientAvatar.layer.cornerRadius = self.patientAvatar.frame.size.width / 2;
    self.patientAvatar.clipsToBounds = YES;
    self.patientAvatar.layer.borderWidth = 1.0f;
    self.patientAvatar.layer.borderColor = [UIColor blackColor].CGColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
