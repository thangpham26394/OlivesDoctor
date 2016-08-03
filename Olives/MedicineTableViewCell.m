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
    [self.backgroundCardView setBackgroundColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.1]];

    self.contentView.backgroundColor = [UIColor clearColor];
    [self setBackgroundColor:[UIColor clearColor]];

    //set up cell for selected
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    [bgColorView.layer setCornerRadius:5.0f];
    [bgColorView.layer setMasksToBounds:NO];
    [bgColorView setBackgroundColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.1]];


    [self setSelectedBackgroundView:bgColorView];


    self.note.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    [self.note.layer setCornerRadius:5.0f];
    [self.note.layer setMasksToBounds:YES];
    [self.unit sizeToFit];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
