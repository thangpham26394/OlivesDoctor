//
//  PickNewMedicalRecordViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/1/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PickNewMedicalRecordViewController : UIViewController
@property (strong,nonatomic) NSDictionary *selectedCategory;
@property(assign,nonatomic) BOOL didAddCategory;
@property(assign,nonatomic) BOOL isEditMedicalRecord;
@end
