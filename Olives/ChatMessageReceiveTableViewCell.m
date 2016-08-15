//
//  ChatMessageReceiveTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/15/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "ChatMessageReceiveTableViewCell.h"

@implementation ChatMessageReceiveTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.bgCardView.layer.cornerRadius = 10.0f;
    [self.bgCardView.layer setMasksToBounds:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
