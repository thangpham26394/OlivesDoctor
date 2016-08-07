//
//  StringDoubleTableViewCell.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StringDoubleTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *backGroundCardView;
@property (weak, nonatomic) IBOutlet UITextField *stringTextField;
@property (weak, nonatomic) IBOutlet UITextField *doubleTextField;

@end
