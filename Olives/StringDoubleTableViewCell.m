//
//  StringDoubleTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "StringDoubleTableViewCell.h"

@implementation StringDoubleTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.backGroundCardView.layer setCornerRadius:5.0f];
    [self.backGroundCardView.layer setMasksToBounds:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
