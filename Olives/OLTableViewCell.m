//
//  OLTableViewCell.m
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 5/24/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "OLTableViewCell.h"

@implementation OLTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.backgroundCardView.layer setCornerRadius:10.0f];
    [self.backgroundCardView.layer setMasksToBounds:NO];
    [self.backgroundCardView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.1]];
    self.backgroundCardView.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.1] CGColor];
    self.backgroundCardView.layer.borderWidth = 5.0f;
    self.image.layer.cornerRadius = self.image.frame.size.width / 2;
    self.image.clipsToBounds = YES;
    self.image.layer.borderWidth = 3.0f;
    self.image.layer.borderColor = [UIColor blackColor].CGColor;
    self.descriptionLabel.backgroundColor =[UIColor clearColor];

    self.contentView.backgroundColor = [UIColor clearColor];
    [self setBackgroundColor:[UIColor clearColor]];

    //set up cell for selected
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    [bgColorView.layer setCornerRadius:10.0f];
    [bgColorView.layer setMasksToBounds:NO];
    [bgColorView setBackgroundColor:[UIColor colorWithRed:173/255.0 green:255/255.0 blue: 47/255.0 alpha:0.3f]];


    [self setSelectedBackgroundView:bgColorView];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
