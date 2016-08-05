//
//  MedicineDetailsTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/27/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MedicineDetailsTableViewController.h"
#import "MedicineTableViewCell.h"
#import "AddOrUpdateMedicineViewController.h"
#import <CoreData/CoreData.h>


@interface MedicineDetailsTableViewController ()
@property(strong,nonatomic) NSDictionary *medicinedic;
@property (strong,nonatomic) NSDictionary *selectedPrescription;
@end

@implementation MedicineDetailsTableViewController

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





-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self loadPrescriptionsFromCoreData];
    NSString *medicineString = [self.selectedPrescription objectForKey:@"Medicine"];
    if ((id)medicineString == [NSNull null]) {
        medicineString =@"";
    }

    NSError *jsonError;
    NSData *objectData = [medicineString dataUsingEncoding:NSUTF8StringEncoding];
    self.medicinedic = [NSJSONSerialization JSONObjectWithData:objectData
                                                       options:NSJSONReadingMutableContainers
                                                         error:&jsonError];
    [self.tableView reloadData];
    
    self.navigationController.topViewController.title=@"Medicines";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMedicine:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}

-(IBAction)addMedicine:(id)sender{
    [self performSegueWithIdentifier:@"addNewMedicine" sender:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    //back ground for tableview view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menuscreen.jpg"]];
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
    return self.medicinedic.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MedicineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"medicineDetailCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *medicineName  = [[self.medicinedic allKeys] objectAtIndex:indexPath.row];
    cell.medicineName.text = medicineName;
    NSDictionary *medicineDic = [self.medicinedic objectForKey:medicineName];

    cell.quantity.text =[NSString stringWithFormat:@"%@", [medicineDic objectForKey:@"Quantity"]];
    cell.unit.text = [medicineDic objectForKey:@"Unit"];
    cell.note.text = [medicineDic objectForKey:@"Note"];

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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"addNewMedicine"])
    {
        AddOrUpdateMedicineViewController * addOrUpdatePrescriptionViewcontroller = [segue destinationViewController];
        addOrUpdatePrescriptionViewcontroller.selectedPrescription = self.selectedPrescription;

    }
}


@end
