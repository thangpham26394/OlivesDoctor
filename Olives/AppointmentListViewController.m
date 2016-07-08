//
//  AppointmentListViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "AppointmentListViewController.h"
#import "AppointmentDetailTableViewCell.h"
@interface AppointmentListViewController ()
@property (weak, nonatomic) IBOutlet UITableView *appointListTableView;
@property (weak, nonatomic) IBOutlet UILabel *chosenDate;
@property (weak, nonatomic) IBOutlet UILabel *totalAppointmentLabel;

-(IBAction)doneButton:(id)sender;
@end

@implementation AppointmentListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.chosenDate.text = self.chosenDateString;
    [self.appointListTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.appointListTableView setShowsVerticalScrollIndicator:NO];
    self.appointListTableView.backgroundColor = [UIColor clearColor];
    //check if device using is 4inch device
    if ( [[UIScreen mainScreen] bounds].size.height == 568) {
        self.chosenDate.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
        self.totalAppointmentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    }else{
        self.chosenDate.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
        self.totalAppointmentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doneButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 10;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppointmentDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"appointmentDetailCell" forIndexPath:indexPath];

    // Configure the cell...

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    [self.appointListTableView deselectRowAtIndexPath:indexPath animated:YES];
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
