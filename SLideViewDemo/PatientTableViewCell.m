//
//  PatientTableViewCell.m
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 5/27/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "PatientTableViewCell.h"

@implementation PatientTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.contentView.backgroundColor = [UIColor clearColor];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.backgroundCardView.layer setCornerRadius:10.0f];
    [self.backgroundCardView.layer setMasksToBounds:NO];
    [self.backgroundCardView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.7]];
    self.backgroundCardView.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.1] CGColor];
    self.backgroundCardView.layer.borderWidth = 5.0f;

    self.avatar.layer.cornerRadius = self.avatar.frame.size.width / 2;
    self.avatar.clipsToBounds = YES;
    self.avatar.layer.borderWidth = 3.0f;
    self.avatar.layer.borderColor = [UIColor blackColor].CGColor;


    self.contentView.backgroundColor = [UIColor clearColor];
    [self setBackgroundColor:[UIColor clearColor]];
   // set up for selected cell
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    [bgColorView.layer setCornerRadius:10.0f];
    [bgColorView.layer setMasksToBounds:NO];
    [bgColorView setBackgroundColor:[UIColor colorWithRed:143/255.0 green:225/255.0 blue: 247/255.0 alpha:0.5f]];


    [self setSelectedBackgroundView:bgColorView];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
