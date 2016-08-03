//
//  MedicineTableViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicineTableViewController : UITableViewController
@property(strong,nonatomic) NSDictionary *selectedPrescription;
@property(assign,nonatomic) BOOL isAddNew;
@end
