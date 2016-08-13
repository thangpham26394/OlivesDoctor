//
//  AlgeryTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/13/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "AlgeryTableViewCell.h"

@implementation AlgeryTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.algeryNoteLabel.layer.cornerRadius = 5.0f;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.algeryNoteLabel.editable = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
