//
//  CurrentPatientTableViewCell.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/11/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurrentPatientTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
