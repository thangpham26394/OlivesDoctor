//
//  CurrentPatientTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/11/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "CurrentPatientTableViewCell.h"

@implementation CurrentPatientTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.removeButton.layer.cornerRadius = 5.0f;
    self.avatar.layer.cornerRadius = self.avatar.frame.size.width / 2;
    self.avatar.clipsToBounds = YES;
    self.avatar.layer.borderWidth = 1.0f;
    self.avatar.layer.borderColor = [UIColor blackColor].CGColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
