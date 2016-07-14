//
//  TimePickerViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/12/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "TimePickerViewController.h"

@interface TimePickerViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *dateTimePicker;
@property (weak, nonatomic) IBOutlet UITextView *noteLabel;

-(IBAction)sendRequestButton:(id)sender;
@end

@implementation TimePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.dateTimePicker setValue:[UIColor whiteColor] forKey:@"textColor"];
    self.noteLabel.layer.cornerRadius = 5.0f;
    [self.noteLabel setShowsVerticalScrollIndicator:NO];

    //set time zone for date time picker to GMT
    [self.dateTimePicker setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];

    //format initial date time
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setDateFormat:@"dd/MM/yyyy HH:mm:ss:SSS"];

    //formt initial date
    NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [dateFormat setLocale:[NSLocale systemLocale]];
    [dateFormat setDateFormat:@"dd/MM/yyyy"];
    NSString *initialDate = [dateFormat stringFromDate:[NSDate date]];

    //set up initial date time for dateTimePicker
    NSString *initialTime = [NSString stringWithFormat:@"%@  00:00:00:000",initialDate];
    NSDate * date = [formatter dateFromString:initialTime];

    [self.dateTimePicker setDate:date];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)sendRequestButton:(id)sender{
    [self showAlertView];
}



-(void)showAlertView{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Request Sent"
                                                               message:@"Your Request will be sent to your patient soon"
                                                               preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              //sent request to API here
                                                              NSLog(@"OK Action!");
                                                              [self.navigationController popViewControllerAnimated:YES];
                                                          }];


    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
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
