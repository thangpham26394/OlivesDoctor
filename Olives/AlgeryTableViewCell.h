//
//  AlgeryTableViewCell.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/13/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlgeryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelCause;
@property (weak, nonatomic) IBOutlet UILabel *labelNote;


@property (weak, nonatomic) IBOutlet UILabel *algeryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *algeryCauseLabel;
@property (weak, nonatomic) IBOutlet UITextView *algeryNoteLabel;

@end
