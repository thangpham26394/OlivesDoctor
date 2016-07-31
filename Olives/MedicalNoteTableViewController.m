//
//  MedicalNoteTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/31/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MedicalNoteTableViewController.h"
#import "ShowDetailInfoMedicalRecordTableViewController.h"
#import "MedicalRecordPresctiptionTableViewController.h"

@interface MedicalNoteTableViewController ()
@property (weak, nonatomic) IBOutlet UITextView *noteView;
@property(assign,nonatomic) CGFloat noteViewHeight;
@property(strong,nonatomic) NSString* medicalNote;

@end

@implementation MedicalNoteTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupGestureRecognizer];
//    self.noteViewHeight = [self.medicalNote boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 20, CGFLOAT_MAX)
//                                                                                         options:NSStringDrawingUsesLineFragmentOrigin
//                                                                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}
//                                                                                         context:nil].size.height;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.topViewController.title=@"Details";
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setupGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self.noteView resignFirstResponder];
}



#pragma mark - Table view data source

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if (indexPath.section ==3) {
//        return self.noteViewHeight + 65;
//    }else{
//        return 45;
//    }
//}
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 2;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    NSLog(@"FFFFFFFFFF %ld",(long)section);
//    if (section ==0) {
//        return 1;
//    }else{
//        return 2;
//    }
//
//}
//
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell;
//    if (indexPath.section ==0) {
//        cell = [tableView dequeueReusableCellWithIdentifier:@"medicalNoteCell" forIndexPath:indexPath];
//        cell.textLabel.text = @"medical note cell";
//    }else{
//        cell = [tableView dequeueReusableCellWithIdentifier:@"detailInfoCell" forIndexPath:indexPath];
//        cell.textLabel.text = @"detail info cell";
//    }

    
//    // Configure the cell...
//    
//    return cell;
//}


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
    if ([[segue identifier] isEqualToString:@"showDetailInformation"])
    {
        ShowDetailInfoMedicalRecordTableViewController *medicalRecordDetail = [segue destinationViewController];
        medicalRecordDetail.infoString = [self.medicalRecordDic objectForKey:@"Info"];
    }
    if ([[segue identifier] isEqualToString:@"medicalRecordPrescription"])
    {
        MedicalRecordPresctiptionTableViewController *medicalRecordPrescriptionDetail = [segue destinationViewController];
        medicalRecordPrescriptionDetail.medicalRecordID = [self.medicalRecordDic objectForKey:@"Id"];
    }
}


@end
