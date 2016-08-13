//
//  ShowNotificationTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/11/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL_SEEN_NOTIFICATION @"http://olive.azurewebsites.net/api/notification/seen?Id="
#define APIURL_GET_APPOINTMENT @"http://olive.azurewebsites.net/api/appointment?Id="
#define APIURL_GET_MEDICALRECORD @"http://olive.azurewebsites.net/api/medical/record?Id="
#define APIURL_GET_PRESCRIPTION @"http://olive.azurewebsites.net/api/medical/prescription?Id="
#define APIURL_GET_MEDICALNOTE @"http://olive.azurewebsites.net/api/medical/note?Id="

#import "ShowNotificationTableViewController.h"
#import "TimePickerViewController.h"
#import "NotificationTableViewCell.h"
#import "MedicalNoteTableViewController.h"
#import "MedicalRecordImagesCollectionViewController.h"
#import "MedicineTableViewController.h"
#import "MedicineImagesCollectionViewController.h"
#import "MedicalRecordExperimentNoteTableViewController.h"
#import "AddNewMedicalNoteViewController.h"
#import <CoreData/CoreData.h>


@interface ShowNotificationTableViewController ()
@property (strong,nonatomic) NSDictionary *responseJSONDataForPendingList ;
@property (strong,nonatomic)NSDictionary *selectedNotification;
@property (strong,nonatomic)NSDictionary *selectedAppointment;
@property (strong,nonatomic)NSDictionary *selectedMedicalRecord;
@property (strong,nonatomic)NSDictionary *selectedPrescription;
@property (strong,nonatomic)NSDictionary *selectedMedicalNote;
@property (strong,nonatomic) NSString* selectedPatientID;
@end

@implementation ShowNotificationTableViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)saveAppointmentInfoToCoreData{
    NSDictionary *appointmentDic = [self.responseJSONDataForPendingList objectForKey:@"Appointment"];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Appointment"];
    NSMutableArray *appointmentObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *appointment;
    //incase the appointment info is already in coredata  -> delete it
    if (appointmentObject.count >0) {

        for (int index=0; index < appointmentObject.count; index++) {
            appointment = [appointmentObject objectAtIndex:index];
            //check if current date status is equal to pending status
            if ([[appointment valueForKey:@"appointmentID"] isEqual:[NSString stringWithFormat:@"%@",[appointmentDic objectForKey:@"Id"]]]) {
                [context deleteObject:appointment];//only delete the date that have status we want
            }

        }
    }

    //save appointment from notification to coredata
    NSString * appointmentID = [appointmentDic valueForKey:@"Id"];
    NSString * dateCreated = [appointmentDic valueForKey:@"Created"];
    NSString * daterId = [[appointmentDic valueForKey:@"Dater"]  valueForKey:@"Id"];
    NSString * daterFirstName = [[appointmentDic valueForKey:@"Dater"] valueForKey:@"FirstName"];
    NSString * daterLastName = [[appointmentDic valueForKey:@"Dater"] valueForKey:@"LastName"];
    NSString * makerId = [[appointmentDic valueForKey:@"Maker"]  valueForKey:@"Id"];
    NSString * makerFirstName = [[appointmentDic valueForKey:@"Maker"] valueForKey:@"FirstName"];
    NSString * makerLastName = [[appointmentDic valueForKey:@"Maker"] valueForKey:@"LastName"];
    NSString * from = [appointmentDic valueForKey:@"From"];
    NSString * to = [appointmentDic valueForKey:@"To"];
    NSString * lastModified = [appointmentDic valueForKey:@"LastModified"];
    NSString * note = [appointmentDic valueForKey:@"Note"];
    NSString * status = [appointmentDic valueForKey:@"Status"];
    NSString * lastModifiedNote = [appointmentDic valueForKey:@"LastModifiedNote"];

    //create new appointment object
    NSManagedObject *newAppointment  = [NSEntityDescription insertNewObjectForEntityForName:@"Appointment" inManagedObjectContext:context];
    //set value for each attribute of new patient before save to core data
    [newAppointment setValue: [NSString stringWithFormat:@"%@", appointmentID] forKey:@"appointmentID"];
    [newAppointment setValue: [NSString stringWithFormat:@"%@", dateCreated] forKey:@"dateCreated"];
    [newAppointment setValue:[NSString stringWithFormat:@"%@", daterId] forKey:@"daterID"];
    [newAppointment setValue:daterFirstName forKey:@"daterFirstName"];
    [newAppointment setValue:daterLastName forKey:@"daterLastName"];
    [newAppointment setValue:[NSString stringWithFormat:@"%@", makerId]  forKey:@"makerID"];
    [newAppointment setValue:makerFirstName forKey:@"makerFirstName"];
    [newAppointment setValue:makerLastName forKey:@"makerLastName"];
    [newAppointment setValue: [NSString stringWithFormat:@"%@", from] forKey:@"from"];
    [newAppointment setValue: [NSString stringWithFormat:@"%@", to] forKey:@"to"];
    [newAppointment setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"lastModified"];
    [newAppointment setValue:note forKey:@"note"];
    [newAppointment setValue: [NSString stringWithFormat:@"%@", status] forKey:@"status"];
    [newAppointment setValue: [NSString stringWithFormat:@"%@", lastModifiedNote] forKey:@"lastModifiedNote"];

    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save Appointment success!");
    }
}

-(void)saveMedicalCategoryToCoreData:(NSDictionary*)categoryDic{

    NSString *categoryID = [categoryDic objectForKey:@"Id"];
    NSString *categoryName = [categoryDic objectForKey:@"Name"];

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalCategories"];
    NSMutableArray *medicalCategoryObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalCategory;

    //if category already have in coredata then update the name of category which have same Id
    BOOL inCoreDataAlready = NO;
    if (medicalCategoryObject.count >0) {
        for (int index=0; index < medicalCategoryObject.count; index++) {
            medicalCategory = [medicalCategoryObject objectAtIndex:index];
            if ([[NSString stringWithFormat:@"%@",categoryID] isEqual:[medicalCategory valueForKey:@"medicalCategoryID"] ]) {
                [medicalCategory setValue:categoryName forKey:@"name"];
                NSLog(@"Update MedicalRecordCategory success!");
                inCoreDataAlready = YES;
            }
        }
    }

    //if category don't have in coredata yet then add new
    if (!inCoreDataAlready) {
        //create new patient object
        NSManagedObject *newMedicalRecord  = [NSEntityDescription insertNewObjectForEntityForName:@"MedicalCategories" inManagedObjectContext:context];
        [newMedicalRecord setValue:[NSString stringWithFormat:@"%@", categoryID]  forKey:@"medicalCategoryID"];
        [newMedicalRecord setValue:categoryName forKey:@"name"];
        // Save the object to persistent store
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save MedicalRecordCategory success!");
        }
    }
    
}

-(void)savePrescriptionToCoreData{
    NSDictionary *prescriptionDic = [self.responseJSONDataForPendingList objectForKey:@"Prescription"];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Prescriptions"];
    NSMutableArray *prescriptionObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *prescription;
    //delete previous prescription
    if (prescriptionObject.count >0) {

        for (int index=0; index < prescriptionObject.count; index++) {
            prescription = [prescriptionObject objectAtIndex:index];
            if ([[prescription valueForKey:@"prescriptionID"] isEqual:[NSString stringWithFormat:@"%@",[prescriptionDic objectForKey:@"Id"]]]) {
                [context deleteObject:prescription]; //only delete prescription that have same id with prescription get from api
            }

        }
    }

    // insert new patients that gotten from API
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


-(void)saveMedicalRecordInfoToCoreData{
    NSDictionary *medicalRecordDic = [self.responseJSONDataForPendingList objectForKey:@"MedicalRecord"];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
    NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalRecord;
    //incase the appointment info is already in coredata  -> delete it
    if (medicalRecordObject.count >0) {

        for (int index=0; index < medicalRecordObject.count; index++) {
            medicalRecord = [medicalRecordObject objectAtIndex:index];
            //check if current date status is equal to pending status
            if ([[medicalRecord valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",[medicalRecordDic objectForKey:@"Id"]]]) {
                [context deleteObject:medicalRecord];//only delete the medical record that have status we want
            }

        }
    }

    //save appointment from notification to coredata
    NSString *medicalRecordID = [medicalRecordDic objectForKey:@"Id"];
    NSString *owner = [[medicalRecordDic objectForKey:@"Owner"] objectForKey:@"Id"];
    NSString *creator = [[medicalRecordDic objectForKey:@"Creator"] objectForKey:@"Id"];
    NSDictionary *category = [medicalRecordDic objectForKey:@"Category"];
    NSString *categoryID = [category objectForKey:@"Id"];
    NSString *info = [medicalRecordDic objectForKey:@"Info"];
    NSString *time = [medicalRecordDic objectForKey:@"Time"];
    NSString *createdDate = [medicalRecordDic objectForKey:@"Created"];
    NSString *lastModified = [medicalRecordDic objectForKey:@"LastModified"];

    [self saveMedicalCategoryToCoreData:category];

    //create new medical record object
    NSManagedObject *newMedicalRecord = [NSEntityDescription insertNewObjectForEntityForName:@"MedicalRecord" inManagedObjectContext:context];
    //set value for each attribute of new patient before save to core data
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", medicalRecordID] forKey:@"medicalRecordID"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", owner] forKey:@"ownerID"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", creator] forKey:@"creatorID"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", categoryID] forKey:@"categoryID"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", info] forKey:@"info"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", time] forKey:@"time"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", createdDate] forKey:@"createdDate"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"lastModified"];

    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save MedicalRecord success!");
    }


}

-(void)saveMedicalNoteToCoreData{

    NSDictionary *medicalNoteDic = [self.responseJSONDataForPendingList objectForKey:@"MedicalNote"];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalNotes"];
    NSMutableArray *medicalNoteObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalNote;


    if (medicalNoteObject.count >0) {
        //delete the old medical note in the same medical record
        for (int index=0; index < medicalNoteObject.count; index++) {
            medicalNote = [medicalNoteObject objectAtIndex:index];
            if ([[medicalNote valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",[medicalNoteDic objectForKey:@"Id"] ]]) {
                [context deleteObject:medicalNote];//only delete medical Note that belong to selected Medical record
                NSLog(@"Delete Medical note success!");
            }

        }
    }
    

    NSString *medicalNoteID = [medicalNoteDic objectForKey:@"Id"];
    NSString *medicalRecordID = [medicalNoteDic objectForKey:@"MedicalRecord"];
    NSString *ownerID = [medicalNoteDic objectForKey:@"Owner"];
    NSString *creatorID = [medicalNoteDic objectForKey:@"Creator"];
    NSString *note = [medicalNoteDic objectForKey:@"Note"];
    NSString *time = [medicalNoteDic objectForKey:@"Time"];
    NSString *created = [medicalNoteDic objectForKey:@"Created"];
    NSString *lastModified = [medicalNoteDic objectForKey:@"LastModified"];

    //create new medical note object
    NSManagedObject *newMedicalNote  = [NSEntityDescription insertNewObjectForEntityForName:@"MedicalNotes" inManagedObjectContext:context];
    [newMedicalNote setValue: [NSString stringWithFormat:@"%@", medicalNoteID] forKey:@"medicalNoteID"];
    [newMedicalNote setValue: [NSString stringWithFormat:@"%@", medicalRecordID] forKey:@"medicalRecordID"];
    [newMedicalNote setValue: [NSString stringWithFormat:@"%@", ownerID] forKey:@"ownerID"];
    [newMedicalNote setValue: [NSString stringWithFormat:@"%@", creatorID] forKey:@"creatorID"];
    [newMedicalNote setValue: [NSString stringWithFormat:@"%@", note] forKey:@"note"];
    [newMedicalNote setValue: [NSString stringWithFormat:@"%@", time] forKey:@"time"];
    [newMedicalNote setValue: [NSString stringWithFormat:@"%@", created] forKey:@"created"];
    [newMedicalNote setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"lastModified"];

    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save Medical note success!");
    }
}


#pragma mark - view controller


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setShowsVerticalScrollIndicator:NO];
    //back ground for tableview view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menuscreen.jpg"]];
    self.tableView.backgroundView = imageView;
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
    return self.notifictionDataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notificationCell" forIndexPath:indexPath];
    NSDictionary *currentNoti = [self.notifictionDataArray objectAtIndex:indexPath.row];
    // Configure the cell...
    cell.notificationMessage.text = [currentNoti objectForKey:@"Message"];

    //get notification created time
    NSString *notiTime = [currentNoti objectForKey:@"Created"];

    NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];

    NSDate *notiDate = [NSDate dateWithTimeIntervalSince1970:[notiTime doubleValue]/1000];

    cell.notificationCreatedTime.text = [dateFormatterToLocal stringFromDate:notiDate];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedNotification = [self.notifictionDataArray objectAtIndex:indexPath.row];
    //if selected notification field is appointment notification
    if (self.notificationType == 0) {
        // get the selected notification
        self.selectedAppointment = [self loadAppointmentDataFromAPIWithID:[self.selectedNotification objectForKey:@"Record"]];
        self.selectedPatientID = [self.selectedNotification objectForKey:@"Broadcaster"];
        [self performSegueWithIdentifier:@"showDetailAppointmentNoti" sender:self];
    }
    if (self.notificationType == 1) {
        // get the selected notification
        self.selectedAppointment = [self loadAppointmentDataFromAPIWithID:[self.selectedNotification objectForKey:@"Record"]];
        self.selectedPatientID = [self.selectedNotification objectForKey:@"Broadcaster"];
        [self performSegueWithIdentifier:@"showDetailAppointmentNoti" sender:self];
    }
    if (self.notificationType == 2) {
        // get the selected notification
        self.selectedAppointment = [self loadAppointmentDataFromAPIWithID:[self.selectedNotification objectForKey:@"Record"]];
        self.selectedPatientID = [self.selectedNotification objectForKey:@"Broadcaster"];
        [self performSegueWithIdentifier:@"showDetailAppointmentNoti" sender:self];
    }
    if (self.notificationType == 3) {
        // get the selected notification

        self.selectedPatientID = [self.selectedNotification objectForKey:@"Broadcaster"];



        //get topic of notification belong to medicalrecord notification
        NSString * topic = [self.selectedNotification objectForKey:@"Topic"];

        //about Medical record
        if ([[NSString stringWithFormat:@"%@", topic ] isEqual:[NSString stringWithFormat:@"1"]]) {
            self.selectedMedicalRecord = [self loadMedicalRecordDataFromAPIWithID:[self.selectedNotification objectForKey:@"Record"]];
            [self performSegueWithIdentifier:@"showMedicalRecordNoti" sender:self];
        }

        //about Medical image
        if ([[NSString stringWithFormat:@"%@", topic ] isEqual:[NSString stringWithFormat:@"2"]]){
            [self performSegueWithIdentifier:@"showMedicalImageNoti" sender:self];
        }

        //about Prescription
        if ([[NSString stringWithFormat:@"%@", topic ] isEqual:[NSString stringWithFormat:@"3"]]) {
            self.selectedPrescription = [self loadPrescriptionDataFromAPIWithID:[self.selectedNotification objectForKey:@"Record"]];
            [self performSegueWithIdentifier:@"showPrescriptionNoti" sender:self];
        }
        //about Prescription image
        if ([[NSString stringWithFormat:@"%@", topic ] isEqual:[NSString stringWithFormat:@"4"]]) {
            self.selectedPrescription = [self loadPrescriptionDataFromAPIWithID:[self.selectedNotification objectForKey:@"Record"]];
            [self performSegueWithIdentifier:@"showPrescriptionImageNoti" sender:self];
        }

        //about Experiment note
        if ([[NSString stringWithFormat:@"%@", topic ] isEqual:[NSString stringWithFormat:@"5"]]) {
            [self performSegueWithIdentifier:@"showExperimentNoteNoti" sender:self];
        }

        //about Medical note
        if ([[NSString stringWithFormat:@"%@", topic ] isEqual:[NSString stringWithFormat:@"6"]]){
            self.selectedMedicalNote = [self loadMedicalNoteDataFromAPIWithID:[self.selectedNotification objectForKey:@"Record"]];
            [self performSegueWithIdentifier:@"showMedicalNoteNoti" sender:self];
        }




    }

    NSString *selectedNotiID = [self.selectedNotification objectForKey:@"Id"];
    [self putSeenNotificationToAPIWithID:selectedNotiID];
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
#pragma mark - handle API connection

-(void)putSeenNotificationToAPIWithID:(NSString *)notificationID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", APIURL_SEEN_NOTIFICATION,notificationID ]];

    // config session
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    NSString *email = [doctor valueForKey:@"email"];
    NSString *password = [doctor valueForKey:@"password"];

    //setup header and body for request
    [urlRequest setHTTPMethod:@"PUT"];
    [urlRequest setValue:email forHTTPHeaderField:@"Email"];
    [urlRequest setValue:password forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONDataForPendingList = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONDataForPendingList != nil) {
                                              }else{
                                              }
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}



-(NSDictionary*)loadAppointmentDataFromAPIWithID:(NSString *)appointmentID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", APIURL_GET_APPOINTMENT,appointmentID ]];

    // config session
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    NSString *email = [doctor valueForKey:@"email"];
    NSString *password = [doctor valueForKey:@"password"];

    //setup header and body for request
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:email forHTTPHeaderField:@"Email"];
    [urlRequest setValue:password forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONDataForPendingList = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];

                                              if (self.responseJSONDataForPendingList != nil) {
                                                  [self saveAppointmentInfoToCoreData];
                                              }else{

                                              }
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return self.responseJSONDataForPendingList;
}

-(NSDictionary*)loadPrescriptionDataFromAPIWithID:(NSString *)prescriptionID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", APIURL_GET_PRESCRIPTION,prescriptionID ]];

    // config session
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    NSString *email = [doctor valueForKey:@"email"];
    NSString *password = [doctor valueForKey:@"password"];

    //setup header and body for request
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:email forHTTPHeaderField:@"Email"];
    [urlRequest setValue:password forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONDataForPendingList = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];

                                              if (self.responseJSONDataForPendingList != nil) {
                                                  [self savePrescriptionToCoreData];
                                              }else{

                                              }
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return self.responseJSONDataForPendingList;
}

-(NSDictionary*)loadMedicalNoteDataFromAPIWithID:(NSString *)medicalNoteID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", APIURL_GET_MEDICALNOTE,medicalNoteID ]];

    // config session
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    NSString *email = [doctor valueForKey:@"email"];
    NSString *password = [doctor valueForKey:@"password"];

    //setup header and body for request
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:email forHTTPHeaderField:@"Email"];
    [urlRequest setValue:password forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONDataForPendingList = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];

                                              if (self.responseJSONDataForPendingList != nil) {
                                                  [self saveMedicalNoteToCoreData];
                                              }else{

                                              }
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return self.responseJSONDataForPendingList;
}


-(NSDictionary*)loadMedicalRecordDataFromAPIWithID:(NSString *)medicalRecordID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", APIURL_GET_MEDICALRECORD,medicalRecordID ]];

    // config session
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    NSString *email = [doctor valueForKey:@"email"];
    NSString *password = [doctor valueForKey:@"password"];

    //setup header and body for request
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:email forHTTPHeaderField:@"Email"];
    [urlRequest setValue:password forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONDataForPendingList = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];

                                              if (self.responseJSONDataForPendingList != nil) {
                                                  [self saveMedicalRecordInfoToCoreData];
                                              }else{

                                              }
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return self.responseJSONDataForPendingList;
}



-(NSDictionary *)getPatientFromCoredataWithID:(NSString*)patientID{
    NSDictionary *patientDic = [[NSDictionary alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
    NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *patient;
    for (int index =0; index<patientObject.count; index++) {
        //get each patient in coredata
        patient = [patientObject objectAtIndex:index];
        if ([[patient valueForKey:@"patientId" ] isEqualToString:patientID]) {
            patientDic = [NSDictionary dictionaryWithObjectsAndKeys:
                          [patient valueForKey:@"patientId" ],@"Id",
                          [patient valueForKey:@"firstName" ],@"FirstName",
                          [patient valueForKey:@"lastName" ],@"LastName",
                          [patient valueForKey:@"birthday" ],@"Birthday",
                          [patient valueForKey:@"phone" ],@"Phone",
                          [patient valueForKey:@"photo" ],@"Photo",
                          [patient valueForKey:@"address" ],@"Address",
                          [patient valueForKey:@"email" ],@"Email",
                          [patient valueForKey:@"weight" ],@"Weight",
                          [patient valueForKey:@"height" ],@"Height",
                          nil];
        }


    }
    return patientDic;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    //show notification about appointment
    if ([[segue identifier] isEqualToString:@"showDetailAppointmentNoti"])
    {
        TimePickerViewController *timePickerController = [segue destinationViewController];
        timePickerController.selectedPatient = [self getPatientFromCoredataWithID:self.selectedPatientID];
        timePickerController.appointmentID = [NSString stringWithFormat:@"%@",[[self.selectedAppointment objectForKey:@"Appointment"] objectForKey:@"Id" ]];
        timePickerController.isNotificationView = YES;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];

        NSTimeInterval dateInterval = [[NSString stringWithFormat:@"%@",[[self.selectedAppointment objectForKey:@"Appointment"] objectForKey:@"From" ]] doubleValue]/1000;
        NSDate *appointmentDate = [NSDate dateWithTimeIntervalSince1970:dateInterval];
        
        timePickerController.chosenDate = [dateFormatter stringFromDate:appointmentDate];
    }
    //show notification about medical record
    if ([[segue identifier] isEqualToString:@"showMedicalRecordNoti"])
    {
        MedicalNoteTableViewController *medicalRecordDetail = [segue destinationViewController];
        medicalRecordDetail.medicalRecordDic = [self.selectedMedicalRecord objectForKey:@"MedicalRecord"];
    }

    //show notification about medical image
    if ([[segue identifier] isEqualToString:@"showMedicalImageNoti"])
    {
        MedicalRecordImagesCollectionViewController *medicalRecordImage= [segue destinationViewController];
        medicalRecordImage.medicalRecordID = [[self.selectedMedicalRecord objectForKey:@"MedicalRecord"] objectForKey:@"Id"];
    }


    //show notification about prescription
    if ([[segue identifier] isEqualToString:@"showPrescriptionNoti"])
    {
        MedicineTableViewController * medicineTableViewcontroller = [segue destinationViewController];
        medicineTableViewcontroller.selectedPrescriptionID = [[self.selectedPrescription objectForKey:@"Prescription" ] objectForKey:@"Id"];
        medicineTableViewcontroller.selectedPatientID = self.selectedPatientID;
    }

    //show notification about prescription image
    if ([[segue identifier] isEqualToString:@"showPrescriptionImageNoti"])
    {
        MedicineImagesCollectionViewController * medicineImageViewcontroller = [segue destinationViewController];
        medicineImageViewcontroller.selectedPrescriptionID = [[self.selectedPrescription objectForKey:@"Prescription" ] objectForKey:@"Id"];
        medicineImageViewcontroller.selectedPartnerID = self.selectedPatientID;

    }

    //show notification about experiment note
    if ([[segue identifier] isEqualToString:@"showExperimentNoteNoti"])
    {
        MedicalRecordExperimentNoteTableViewController * experimentNoteViewcontroller = [segue destinationViewController];
        experimentNoteViewcontroller.experimentNoteID = [self.selectedNotification objectForKey:@"Record"];

    }

    //show notification about prescription
    if ([[segue identifier] isEqualToString:@"showMedicalNoteNoti"])
    {
        AddNewMedicalNoteViewController * addNewMedicalNoteViewcontroller = [segue destinationViewController];
        addNewMedicalNoteViewcontroller.selectedMedicalNote = [self.selectedMedicalNote objectForKey:@"MedicalNote"];

    }
}


@end
