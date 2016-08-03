//
//  StringStringTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/2/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "StringStringTableViewCell.h"

@implementation StringStringTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.backgroundCardView.layer setCornerRadius:5.0f];
    [self.backgroundCardView.layer setMasksToBounds:NO];
    self.valueTextView.layer.cornerRadius = 5.0f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
