//
//  UpdateDetailInfoMedicalRecordViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/2/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UpdateDetailInfoMedicalRecordViewController : UIViewController
@property(strong,nonatomic) NSDictionary *info;
@property(strong,nonatomic) NSMutableDictionary *totalInfo;
@property(strong,nonatomic) NSDictionary *selectedMedicalRecord;
@property(strong,nonatomic) NSString *selectedInfoKey;
@end
