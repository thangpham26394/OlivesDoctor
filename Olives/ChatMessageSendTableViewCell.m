//
//  ChatMessageSendTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/15/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "ChatMessageSendTableViewCell.h"

@implementation ChatMessageSendTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.message.userInteractionEnabled = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
