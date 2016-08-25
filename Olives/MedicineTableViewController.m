//
//  MedicineTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MedicineTableViewController.h"
#import "MedicineDetailsTableViewController.h"
#import "MedicineImagesCollectionViewController.h"
#import "AddNewPrescriptionViewController.h"
#import <CoreData/CoreData.h>

@interface MedicineTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteView;
@property(assign,nonatomic) CGFloat noteViewHeight;
@property (strong,nonatomic) NSDictionary *selectedPrescription;
@end

@implementation MedicineTableViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)loadPrescriptionsFromCoreData{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Prescriptions"];
    NSMutableArray *prescriptionObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *prescription;
    for (int index =0; index<prescriptionObject.count; index++) {
        //get each patient in coredata
        prescription = [prescriptionObject objectAtIndex:index];
        if ([[prescription valueForKey:@"prescriptionID"] isEqual:[NSString stringWithFormat:@"%@",self.selectedPrescriptionID]]) {
            NSDictionary *prescriptionDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [prescription valueForKey:@"prescriptionID" ],@"Id",
                                            [prescription valueForKey:@"medicalRecord" ],@"MedicalRecord",
                                            [prescription valueForKey:@"from" ],@"From",
                                            [prescription valueForKey:@"to" ],@"To",
                                            [prescription valueForKey:@"name" ],@"Name",
                                            [prescription valueForKey:@"medicine" ],@"Medicine",
                                            [prescription valueForKey:@"note" ],@"Note",
                                            [prescription valueForKey:@"ownerID" ],@"Owner",
                                            [prescription valueForKey:@"createdDate" ],@"Created",
                                            [prescription valueForKey:@"lastModified" ],@"LastModified",
                                            nil];
            self.selectedPrescription = prescriptionDic;
        }

    }
    
}



//-(void)viewWillLayoutSubviews{
//    CGFloat fixedWidth = self.noteView.frame.size.width;
//    CGSize newSize = [self.noteView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
//    CGRect newFrame = self.noteView.frame;
//    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
//    self.noteView.frame = newFrame;
//}



-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self loadPrescriptionsFromCoreData];
    NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];

    NSDate *from = [NSDate dateWithTimeIntervalSince1970:[[self.selectedPrescription objectForKey:@"From"] doubleValue]/1000];
    NSDate *to = [NSDate dateWithTimeIntervalSince1970:[[self.selectedPrescription objectForKey:@"To"] doubleValue]/1000];
    NSDate *fromDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:from]];
    NSDate *toDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:to]];




    self.timeLabel.text = [NSString stringWithFormat:@"From:%@ to:%@",[dateFormatterToLocal stringFromDate:fromDateLocal],[dateFormatterToLocal stringFromDate:toDateLocal]];
    self.noteView.text=[self.selectedPrescription objectForKey:@"Note"];
    [self.noteView setUserInteractionEnabled:NO];
    [self.noteView sizeToFit];

    self.noteViewHeight = [[self.selectedPrescription objectForKey:@"Note"] boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 20, CGFLOAT_MAX)
                                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}
                                                                                         context:nil].size.height;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.isNotificationView) {
        self.canEdit = YES;
    }
    NSLog(@"-------------------------%@",self.selectedPrescriptionID);
    [self setupGestureRecognizer];
}
-(void) setupGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self.noteView resignFirstResponder];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section ==2) {
        return self.noteViewHeight + 60;
    }else{
        return 45;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        if (!self.canEdit) {
            [self showAlertError:@"You don't have permission in this medical record"];
        }else{
            [self performSegueWithIdentifier:@"editMedicineInfo" sender:self];
        }

    }
}

//show alert message for error
-(void)showAlertError:(NSString *)errorString{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:errorString
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {}];
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}

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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"showListMedicines"])
    {
        MedicineDetailsTableViewController * medicineDetailTableViewcontroller = [segue destinationViewController];
        medicineDetailTableViewcontroller.selectedPrescriptionID = self.selectedPrescriptionID ;
        medicineDetailTableViewcontroller.canEdit = self.canEdit;

    }
    if ([[segue identifier] isEqualToString:@"showPrescriptionImage"])
    {
        MedicineImagesCollectionViewController * medicineImageColectionViewcontroller = [segue destinationViewController];
        medicineImageColectionViewcontroller.selectedPrescriptionID = [self.selectedPrescription objectForKey:@"Id"];
        medicineImageColectionViewcontroller.selectedPartnerID = self.selectedPatientID;
        medicineImageColectionViewcontroller.canEdit = self.canEdit;

    }

    if ([[segue identifier] isEqualToString:@"editMedicineInfo"])
    {
        AddNewPrescriptionViewController * addNewPrescriptionViewcontroller = [segue destinationViewController];
        addNewPrescriptionViewcontroller.selectedPrescription = self.selectedPrescription;
        addNewPrescriptionViewcontroller.canEdit = self.canEdit;

    }
}


@end
