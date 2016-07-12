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

@end

@implementation TimePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.dateTimePicker setValue:[UIColor whiteColor] forKey:@"textColor"];
    self.noteLabel.layer.cornerRadius = 5.0f;
    [self.noteLabel setShowsVerticalScrollIndicator:NO];
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
