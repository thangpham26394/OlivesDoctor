//
//  DoctorNoteTableViewCell.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/17/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DoctorNoteTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *noteLabel;

@end
