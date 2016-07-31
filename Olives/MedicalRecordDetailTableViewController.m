//
//  MedicalRecordDetailTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MedicalRecordDetailTableViewController.h"
#import "MedicalNoteTableViewController.h"
@interface MedicalRecordDetailTableViewController ()
@property(strong,nonatomic) NSDictionary *selectedMedicalRecord;
@end

@implementation MedicalRecordDetailTableViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"MedicalRecord";
}

//-(void)viewWillDisappear:(BOOL)animated{
//    [super viewWillAppear:YES];
//    self.navigationController.topViewController.title=@"";
//    NSLog(@"unload");
//}

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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.medicalRecordArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"medicalInfoCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:@"medicalInfoCell"];

    }
    // Configure the cell...
    NSDictionary *dic = [self.medicalRecordArray objectAtIndex:indexPath.row];
    NSString *time = [dic objectForKey:@"Time"];


    NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];

    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]/1000];

    NSDate *timeDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:timeDate]];

    cell.textLabel.text = [NSString stringWithFormat:@"%@",[dateFormatterToLocal stringFromDate:timeDateLocal]];
    //cell.detailTextLabel.text = @"details";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    self.selectedMedicalRecord = [self.medicalRecordArray objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"medicalNoteAndDetailInfo" sender:self];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"medicalNoteAndDetailInfo"])
    {
        MedicalNoteTableViewController *medicalRecordDetail = [segue destinationViewController];
        medicalRecordDetail.medicalRecordDic = self.selectedMedicalRecord;
    }
}


@end
