//
//  AddNewMedicalNoteViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 8/6/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddNewMedicalNoteViewController : UIViewController
@property (strong,nonatomic) NSString *selectedMedicalRecordId;
@property(strong,nonatomic) NSDictionary *selectedMedicalNote;
@property (assign,nonatomic)BOOL canEdit;
@property (assign,nonatomic)BOOL isNotificationView;
@end
