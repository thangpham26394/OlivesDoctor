//
//  StringStringTableViewCell.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/2/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StringStringTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextView *valueTextView;
@property (weak, nonatomic) IBOutlet UIView *backgroundCardView;


@end
