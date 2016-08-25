//
//  MedicineTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicineTableViewController : UITableViewController
@property(strong,nonatomic) NSString *selectedPrescriptionID;
@property(strong,nonatomic) NSString *selectedPatientID;
@property (assign,nonatomic)BOOL canEdit;
@end
