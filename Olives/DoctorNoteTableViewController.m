//
//  DoctorNoteTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/17/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "DoctorNoteTableViewController.h"
#import "DoctorNoteTableViewCell.h"
@interface DoctorNoteTableViewController ()
@property(assign,nonatomic) CGFloat noteLabelHeight;
@end

@implementation DoctorNoteTableViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Diary";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
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

-(IBAction)addInfo:(id)sender{
    NSLog(@"add diary");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"doctorNoteCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"doctorNoteCell"];

    }
    // Configure the cell...

    NSString *doctorNote ;
    NSString *dateTime;
    if (indexPath.row %2 ==0) {
      dateTime = @"20/10/2010";
      doctorNote  = @"phát hiện triệu chứng ung thư máu, mỡ máu rất cao, mức độ đường huyết không ổn định can som phat hien va dieu tri de tranh nhung bien chung sau nay khong mong muon phát hiện triệu chứng ung thư máu, mỡ máu rất cao, mức độ đường huyết không ổn định can som phat hien va dieu tri de tranh nhung bien chung sau nay khong mong muon";
    }else{
        dateTime = @"1/11/2011";
        doctorNote  = @"phát hiện triệu chứng ung thư máu, mỡ máu rất cao, mức độ đường huyết không ổn định";
    }
    cell.textLabel.text = dateTime;
    cell.detailTextLabel.text =doctorNote;

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;

//    self.noteLabelHeight=[doctorNote sizeWithFont:[UIFont fontWithName:@"Arial" size:14] constrainedToSize:CGSizeMake(500, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height;

//    self.noteLabelHeight = [doctorNote sizeWithFont:[UIFont systemFontOfSize:20]
//       constrainedToSize:CGSizeMake(self.view.bounds.size.width - 40, CGFLOAT_MAX) // - 40 For cell padding
//           lineBreakMode:NSLineBreakByWordWrapping].height;

    self.noteLabelHeight = [doctorNote boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 40, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}
                                              context:nil].size.height;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.noteLabelHeight + 50;
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
