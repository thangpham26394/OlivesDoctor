//
//  AddNewPrescriptionViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/5/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddNewPrescriptionViewController : UIViewController
@property(strong,nonatomic) NSString*selectedMedicalRecordId;
@property(strong,nonatomic) NSDictionary *selectedPrescription;
@end
