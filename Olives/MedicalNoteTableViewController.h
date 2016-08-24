//
//  MedicalNoteTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/31/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicalNoteTableViewController : UITableViewController
@property (strong,nonatomic) NSDictionary *medicalRecordDic;
@property (assign,nonatomic)BOOL isNotificationView;
@property (assign,nonatomic)BOOL canEdit;
@end
