//
//  MedicalRecordNoteDetailTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/1/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicalRecordNoteDetailTableViewController : UITableViewController
@property (strong,nonatomic) NSString *medicalRecordID;
@property(assign,nonatomic) BOOL isAddNew;
@end
