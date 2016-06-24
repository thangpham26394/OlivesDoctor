//
//  OLTableViewCell.h
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 5/24/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OLTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UIView *backgroundCardView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
