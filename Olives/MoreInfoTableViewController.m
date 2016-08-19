//
//  MoreInfoTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/13/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MoreInfoTableViewController.h"
#import "AddictionTableViewController.h"
#import "AlgeryTableViewController.h"
#import "HeartBeatViewController.h"
#import "BloodSugarViewController.h"
#import "BloodPresureViewController.h"
@interface MoreInfoTableViewController ()

@end

@implementation MoreInfoTableViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.topViewController.title=@"More Info";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 1;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showAddiction"])
    {
        AddictionTableViewController *addictionTableViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        addictionTableViewController.selectedPatientID = self.selectedPatientID;
    }

    if ([[segue identifier] isEqualToString:@"showAlgery"])
    {
        AlgeryTableViewController *algeryTableViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        algeryTableViewController.selectedPatientID = self.selectedPatientID;
    }
    if ([[segue identifier] isEqualToString:@"showHeartBeat"])
    {
        HeartBeatViewController *heartBeatViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        heartBeatViewController.selectedPatientID = self.selectedPatientID;
    }
    if ([[segue identifier] isEqualToString:@"showBloodSugar"])
    {
        BloodSugarViewController *bloodSugarViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        bloodSugarViewController.selectedPatientID = self.selectedPatientID;
    }
    if ([[segue identifier] isEqualToString:@"showBloodPressure"])
    {
        BloodPresureViewController *bloodPressureViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        bloodPressureViewController.selectedPatientID = self.selectedPatientID;
    }
}


@end
