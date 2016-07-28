//
//  MedicineTableViewCell.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/27/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MedicineTableViewCell.h"

@implementation MedicineTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.backgroundCardView.layer setCornerRadius:5.0f];
    [self.backgroundCardView.layer setMasksToBounds:NO];
    [self.backgroundCardView setBackgroundColor:[UIColor whiteColor]];

    self.contentView.backgroundColor = [UIColor clearColor];
    [self setBackgroundColor:[UIColor clearColor]];

    self.note.backgroundColor = [UIColor lightGrayColor];
    [self.note.layer setCornerRadius:5.0f];
    [self.note.layer setMasksToBounds:YES];
    [self.unit sizeToFit];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
