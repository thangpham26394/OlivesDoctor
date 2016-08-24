//
//  MedicalRecordNoteDetailTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/1/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicalRecordNoteDetailTableViewController : UITableViewController
@property (strong,nonatomic) NSDictionary *selectedMedicalRecord;
@property (assign,nonatomic)BOOL canEdit;
@end
