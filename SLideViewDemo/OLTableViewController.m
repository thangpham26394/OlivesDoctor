//
//  OLTableViewController.m
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 5/24/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "OLTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OLTableViewCell.h"
@interface OLTableViewController ()

@end

@implementation OLTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blurbackgroundIOS.jpg"]];

    self.tableView.backgroundView = imageView;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 6;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OLTableViewCell *cell;
    // Configure the cell...
    if (indexPath.row ==0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"homeCell" forIndexPath:indexPath];
        cell.image.image = [UIImage imageNamed: @"sanji.jpeg"];
        cell.descriptionLabel.text = @"Home";
    }else if (indexPath.row ==1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"patientCell" forIndexPath:indexPath];
        cell.image.image = [UIImage imageNamed: @"strawhat.png"];
        cell.descriptionLabel.text = @"My Patients";
    }else if (indexPath.row==2){
        cell = [tableView dequeueReusableCellWithIdentifier:@"appointmentCell" forIndexPath:indexPath];
        cell.image.image = [UIImage imageNamed: @"chopper.jpeg"];
        cell.descriptionLabel.text = @"Appointments";
    }else if(indexPath.row ==3){
        cell = [tableView dequeueReusableCellWithIdentifier:@"loanCell" forIndexPath:indexPath];
        cell.image.image = [UIImage imageNamed: @"nami.jpeg"];
        cell.descriptionLabel.text = @"My Loans";
    }
    else if(indexPath.row ==4){
        cell = [tableView dequeueReusableCellWithIdentifier:@"settingCell" forIndexPath:indexPath];
        cell.image.image = [UIImage imageNamed: @"robin.jpeg"];
        cell.descriptionLabel.text = @"Setting";
    }else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"outCell" forIndexPath:indexPath];
        cell.image.image = [UIImage imageNamed: @"zoro.jpeg"];
        cell.descriptionLabel.text = @"Out";
    }



    return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
