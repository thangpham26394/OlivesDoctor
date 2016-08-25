//
//  MedicineDetailsTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/27/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicineDetailsTableViewController : UITableViewController
@property(strong,nonatomic) NSString *selectedPrescriptionID;
@property (assign,nonatomic)BOOL canEdit;
@end
