//
//  ChatMessageSendTableViewCell.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/15/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatMessageSendTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *bgCardView;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;


@end
