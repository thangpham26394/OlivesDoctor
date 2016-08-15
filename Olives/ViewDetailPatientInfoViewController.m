//
//  ViewDetailPatientInfoViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/12/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "ViewDetailPatientInfoViewController.h"

@interface ViewDetailPatientInfoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UITextField *birthdayTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *weightTextField;
@property (weak, nonatomic) IBOutlet UITextField *heightTextField;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;

@end

@implementation ViewDetailPatientInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.avatar.layer.cornerRadius = self.avatar.frame.size.width / 2;
    self.avatar.clipsToBounds = YES;
    self.avatar.layer.borderWidth = 1.0f;
    self.avatar.layer.borderColor = [UIColor whiteColor].CGColor;

    [self.noteTextView setEditable:NO];
    self.noteTextView.layer.cornerRadius = 5.0f;
    UIImage *img;
    NSData *data = [self.selectedPatient objectForKey:@"Photo"];
    if (data !=nil) {
        img = [[UIImage alloc] initWithData:data];
    }else{
        img = [UIImage imageNamed:@"nullAvatar"];
    }

    self.avatar.image = img; //set avatar

    NSDictionary *patientDic = [self.selectedPatient objectForKey:@"Source"];

    self.nameLabel.text = [NSString stringWithFormat:@"%@%@", [patientDic objectForKey:@"FirstName"] ,[patientDic objectForKey:@"LastName"] ];

    NSString *birthdayString = [patientDic objectForKey:@"Birthday"];
    //convert time interval to NSDate type
    NSDate *birthdayUNIXDate = [NSDate dateWithTimeIntervalSince1970:[birthdayString doubleValue]/1000];
    NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM-dd-yyyy"];
    
    self.birthdayTextField.text = [dateFormatterToLocal stringFromDate:birthdayUNIXDate];
    if ([patientDic objectForKey:@"Phone"] != [NSNull null]) {
        self.phoneTextField.text = [patientDic objectForKey:@"Phone"];
    }

    if ([patientDic objectForKey:@"Address"] != [NSNull null]) {
        self.addressTextField.text = [patientDic objectForKey:@"Address"];
    }

    if ([patientDic objectForKey:@"Weight"] != [NSNull null]) {
        self.weightTextField.text = [patientDic objectForKey:@"Weight"];
    }

    if ([patientDic objectForKey:@"Height"] != [NSNull null]) {
        self.heightTextField.text = [patientDic objectForKey:@"Height"];
    }

    if ([patientDic objectForKey:@"Note"] != [NSNull null]) {
        self.noteTextView.text = [patientDic objectForKey:@"Note"];
    }




    self.birthdayTextField.userInteractionEnabled = NO;
    self.phoneTextField.userInteractionEnabled = NO;
    self.addressTextField.userInteractionEnabled = NO;
    self.weightTextField.userInteractionEnabled = NO;
    self.heightTextField.userInteractionEnabled = NO;
    self.noteTextView.userInteractionEnabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
