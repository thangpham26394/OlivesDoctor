//
//  MedicalRecordPresctiptionTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/31/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicalRecordPresctiptionTableViewController : UITableViewController
@property(strong,nonatomic) NSString *medicalRecordID;
@property (assign,nonatomic)BOOL canEdit;
@end
