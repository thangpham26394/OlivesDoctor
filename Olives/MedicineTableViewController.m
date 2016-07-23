//
//  MedicineTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MedicineTableViewController.h"

@interface MedicineTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteView;
@property(assign,nonatomic) CGFloat noteViewHeight;

@end

@implementation MedicineTableViewController
//-(void)viewWillLayoutSubviews{
//    CGFloat fixedWidth = self.noteView.frame.size.width;
//    CGSize newSize = [self.noteView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
//    CGRect newFrame = self.noteView.frame;
//    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
//    self.noteView.frame = newFrame;
//}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *prescriptionNote = @"phát hiện triệu chứng ung thư máu, mỡ máu rất cao, mức độ đường huyết không ổn định can som phat hien va dieu tri de tranh nhung bien chung sau nay khong mong muon phát hiện triệu chứng ung thư máu, mỡ máu rất cao, mức độ đường huyết không ổn định can som phat hien va dieu tri de tranh nhung bien chung sau nay khong mong muon";
    self.noteView.text=prescriptionNote;
    [self.noteView sizeToFit];

    self.noteViewHeight = [prescriptionNote boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 20, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}
                                                    context:nil].size.height;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section ==2) {
        return self.noteViewHeight + 65;
    }else{
        return 45;
    }
}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"medicineImagesCell" forIndexPath:indexPath];
//    
//    // Configure the cell...
//    cell.textLabel.text = @"hihihi";
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
