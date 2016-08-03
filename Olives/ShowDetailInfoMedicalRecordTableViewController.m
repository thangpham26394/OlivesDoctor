//
//  ShowDetailInfoMedicalRecordTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/31/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "ShowDetailInfoMedicalRecordTableViewController.h"
#import "UpdateDetailInfoMedicalRecordViewController.h"
#import "StringStringTableViewCell.h"
@interface ShowDetailInfoMedicalRecordTableViewController ()
@property(strong,nonatomic) NSMutableDictionary *info;
@property(strong,nonatomic) NSString *selectedInfoKey;
@property(assign,nonatomic) CGFloat noteLabelHeight;
@end

@implementation ShowDetailInfoMedicalRecordTableViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Medical Info";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}

-(IBAction)addInfo:(id)sender{
    [self performSegueWithIdentifier:@"addMedicalRecordInfo" sender:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    NSError *jsonError;
    NSData *objectData = [[self.selectedMedicalRecord objectForKey:@"Info"] dataUsingEncoding:NSUTF8StringEncoding];
    self.info = [NSJSONSerialization JSONObjectWithData:objectData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&jsonError];
    if (self.info ==nil) {
        self.info = [[NSMutableDictionary alloc]init];
    }
    
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
    return self.info.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.noteLabelHeight + 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StringStringTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailInfoCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *key = [[self.info allKeys] objectAtIndex:indexPath.row];
    cell.nameTextField.text = key;
    cell.valueTextView.text = [self.info objectForKey:key];
    cell.nameTextField.userInteractionEnabled = NO;
    cell.valueTextView.userInteractionEnabled = NO;

    self.noteLabelHeight = [[self.info objectForKey:key] boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 40, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}
                                                    context:nil].size.height;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // get the selected string string info
    self.selectedInfoKey = [[self.info allKeys] objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"updateMedicalRecordInfo" sender:self];
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
    if ([[segue identifier] isEqualToString:@"addMedicalRecordInfo"])
    {
        UpdateDetailInfoMedicalRecordViewController *updateMedicalRecordDetail = [segue destinationViewController];
        updateMedicalRecordDetail.totalInfo = [self.info mutableCopy];
        updateMedicalRecordDetail.selectedMedicalRecord = self.selectedMedicalRecord;
    }
    if ([[segue identifier] isEqualToString:@"updateMedicalRecordInfo"])
    {
        UpdateDetailInfoMedicalRecordViewController *updateMedicalRecordDetail = [segue destinationViewController];
        updateMedicalRecordDetail.totalInfo = self.info ;
        updateMedicalRecordDetail.selectedMedicalRecord = self.selectedMedicalRecord;//for get id and category id of medical record that selected
        updateMedicalRecordDetail.selectedInfoKey = self.selectedInfoKey;
    }
}

- (IBAction)unwindToShowDetailMedicalRecordInfor:(UIStoryboardSegue *)unwindSegue
{
    UpdateDetailInfoMedicalRecordViewController* sourceViewController = unwindSegue.sourceViewController;
    NSDictionary *newInfo = sourceViewController.info;

    if (newInfo !=nil) {
        NSString *key = [[newInfo allKeys] objectAtIndex:0] ;
        NSString *value = [newInfo objectForKey:key];
        [self.info setObject:value forKey:key];
    }
    [self.tableView reloadData];
}

@end
