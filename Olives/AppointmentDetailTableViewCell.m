//
//  AppointmentDetailTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/20/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "AppointmentDetailTableViewCell.h"

@implementation AppointmentDetailTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.nameLabel.adjustsFontSizeToFitWidth = YES;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
