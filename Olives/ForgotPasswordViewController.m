//
//  ForgotPasswordViewController.m
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 6/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "ForgotPasswordViewController.h"

@interface ForgotPasswordViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *confirmEmailButton;

@end

@implementation ForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Set up confirm email button
    [self.confirmEmailButton.layer setCornerRadius:self.confirmEmailButton.frame.size.height/2+1];
    self.confirmEmailButton.layer.shadowColor = [UIColor colorWithRed:0/255.0 green:150/255.0 blue:150/255.0 alpha:0.5f].CGColor;
    self.confirmEmailButton.layer.shadowOffset = CGSizeMake(0.0f, 10.0f);
    self.confirmEmailButton.layer.shadowOpacity = 0.5f;
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
