//
//  MedicalRecordPresctiptionTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/31/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/prescription/filter"
#import "MedicalRecordPresctiptionTableViewController.h"
#import "MedicineTableViewController.h"
#import "AddNewPrescriptionViewController.h"
#import <CoreData/CoreData.h>

@interface MedicalRecordPresctiptionTableViewController ()
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *prescriptionArray;
@property (strong,nonatomic) NSDictionary *selectedPrescription;
@end

@implementation MedicalRecordPresctiptionTableViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)loadPrescriptionsFromCoreDataWhenAPIFail{
    NSMutableArray *prescriptionArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Prescriptions"];
    NSMutableArray *prescriptionObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *prescription;
    for (int index =0; index<prescriptionObject.count; index++) {
        //get each patient in coredata
        prescription = [prescriptionObject objectAtIndex:index];
        //only load the prescription that have same medicalrecord id with selected medicalrecord
        if ([[prescription valueForKey:@"medicalRecord"] isEqual:self.medicalRecordID]) {
            NSDictionary *appointmentDic = [NSDictionary dictionaryWithObjectsAndKeys:
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
            [prescriptionArrayForFailAPI addObject:appointmentDic];
        }

    }
    self.prescriptionArray = (NSArray*)prescriptionArrayForFailAPI;

}

-(void)savePrescriptionToCoreData{
    self.prescriptionArray = [self.responseJSONData objectForKey:@"Prescriptions"];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Prescriptions"];
    NSMutableArray *prescriptionObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *prescription;
    //delete previous prescription
    if (prescriptionObject.count >0) {

        for (int index=0; index < prescriptionObject.count; index++) {
            prescription = [prescriptionObject objectAtIndex:index];
            if ([[NSString stringWithFormat:@"%@",[prescription valueForKey:@"medicalRecord"] ] isEqual: [NSString stringWithFormat:@"%@",self.medicalRecordID]]) {
                [context deleteObject:prescription]; //only delete prescription of current medical record
            }

        }
    }

    // insert new prescription of selected medicalrecord that gotten from API
    for (int index = 0; index < self.prescriptionArray.count; index++) {
        NSDictionary *prescriptionDic = self.prescriptionArray[index];

        NSString *prescriptionID = [prescriptionDic objectForKey:@"Id"];
        NSString *medicalRecord = [prescriptionDic objectForKey:@"MedicalRecord"];
        NSString *from = [prescriptionDic objectForKey:@"From"];
        NSString *to = [prescriptionDic objectForKey:@"To"];
        NSString *name = [prescriptionDic objectForKey:@"Name"];
        NSString *medicine = [prescriptionDic objectForKey:@"Medicine"];
        NSString *note = [prescriptionDic objectForKey:@"Note"];
        NSString *ownerID = [prescriptionDic objectForKey:@"Owner"];
        NSString *createdDate = [prescriptionDic objectForKey:@"Created"];
        NSString *lastModified = [prescriptionDic objectForKey:@"LastModified"];


        //create new patient object
        NSManagedObject *newPrescription  = [NSEntityDescription insertNewObjectForEntityForName:@"Prescriptions" inManagedObjectContext:context];
        //set value for each attribute of new patient before save to core data
        [newPrescription setValue: [NSString stringWithFormat:@"%@", prescriptionID] forKey:@"prescriptionID"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", medicalRecord] forKey:@"medicalRecord"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", from] forKey:@"from"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", to] forKey:@"to"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", name] forKey:@"name"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", medicine] forKey:@"medicine"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", note] forKey:@"note"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", ownerID] forKey:@"ownerID"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", createdDate] forKey:@"createdDate"];
        [newPrescription setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"lastModified"];


        NSError *error = nil;
        // Save the object to persistent store
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save Prescription success!");
        }
    }
}
#pragma mark - Connect to API function



-(void)loadPresciptionDataFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Mode" :  @"0",
                              @"Sort" : @"1",
                              @"Direction":@"0",
                              @"MedicalRecord":self.medicalRecordID,
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];

    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    //NSURLSession *defaultSession = [NSURLSession sharedSession];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];


    //setup header and body for request
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    [urlRequest setHTTPBody:jsondata];
    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);

    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONData != nil) {
                                                  [self savePrescriptionToCoreData];
                                              }else{
                                                  [self loadPrescriptionsFromCoreDataWhenAPIFail];
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              //self.patientArray = [self loadPatientFromCoreDataWhenAPIFail];
                                              [self loadPrescriptionsFromCoreDataWhenAPIFail];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Medical Presctiption";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}

-(IBAction)addInfo:(id)sender{
    if (!self.canEdit) {
        [self showAlertError:@"You don't have permission in this medical record"];
        return;
    }
    [self performSegueWithIdentifier:@"addMedicalRecordPrescription" sender:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

        [self loadPresciptionDataFromAPI];
        [self.tableView reloadData];


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
    return self.prescriptionArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"medicalRecordPrescription" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];
    NSString *name;
    if ([self.prescriptionArray[indexPath.row] objectForKey:@"Name"] != [NSNull null]) {
        name = [self.prescriptionArray[indexPath.row] objectForKey:@"Name"];
    }else{
        name = @"no name";
    }
//    NSString *toString = [self.prescriptionArray[indexPath.row] objectForKey:@"To"];
//    NSDate *fromDate = [NSDate dateWithTimeIntervalSince1970:[fromString doubleValue]/1000];
//    NSDate *toDate = [NSDate dateWithTimeIntervalSince1970:[toString doubleValue]/1000];
//    NSDate *fromDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:fromDate]];
//    NSDate *toDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:toDate]];
    cell.textLabel.text = name;
    cell.detailTextLabel.text = @"Details";

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedPrescription = self.prescriptionArray[indexPath.row];
    if (!self.canEdit) {
        [self showAlertError:@"You don't have permission in this medical record"];
    }else{
        [self performSegueWithIdentifier:@"medicalRecordPrescriptionShowDetail" sender:self];
    }


    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

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
    if ([[segue identifier] isEqualToString:@"medicalRecordPrescriptionShowDetail"])
    {
        MedicineTableViewController * medicineTableViewcontroller = [segue destinationViewController];
        medicineTableViewcontroller.selectedPrescriptionID = [self.selectedPrescription objectForKey:@"Id"];

    }
    if ([[segue identifier] isEqualToString:@"addMedicalRecordPrescription"])
    {
        AddNewPrescriptionViewController * addNewPrescriptionViewcontroller = [segue destinationViewController];
        addNewPrescriptionViewcontroller.selectedMedicalRecordId = self.medicalRecordID;
        addNewPrescriptionViewcontroller.canEdit = self.canEdit;
    }


}


@end
