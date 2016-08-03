//
//  MedicalRecordDetailTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicalRecordDetailTableViewController : UITableViewController
@property(strong,nonatomic) NSMutableArray *medicalRecordArray;
@property (strong,nonatomic)NSDictionary *selectedCategory;
@property(strong,nonatomic) NSString *selectedPatientID;
@end
