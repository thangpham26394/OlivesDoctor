//
//  MedicalRecordImageShowViewController.h
//  Olives
//
//  Created by Tony Tony Chopper on 7/17/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MedicalRecordImageShowViewController : UIViewController<UIScrollViewDelegate,UIGestureRecognizerDelegate>
@property (strong,nonatomic) UIImage *displayImage;
@end
