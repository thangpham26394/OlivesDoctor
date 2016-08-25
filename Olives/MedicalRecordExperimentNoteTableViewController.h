//
//  MedicalRecordExperimentNoteTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicalRecordExperimentNoteTableViewController : UIViewController<UITextFieldDelegate>
@property (strong,nonatomic) NSString *experimentNoteID;
@property (assign,nonatomic)BOOL canEdit;
@property (assign,nonatomic)BOOL isNotificationView;
@end
