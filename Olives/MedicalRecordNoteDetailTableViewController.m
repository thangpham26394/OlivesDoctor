//
//  MedicalRecordNoteDetailTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/1/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/note/filter"
#import "MedicalRecordNoteDetailTableViewController.h"
#import "DoctorNoteTableViewCell.h"
#import "AddNewMedicalNoteViewController.h"
#import <CoreData/CoreData.h>


@interface MedicalRecordNoteDetailTableViewController ()
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *medicalNoteArray;
@property (strong,nonatomic) NSDictionary *selectedMedicalNote;
@end

@implementation MedicalRecordNoteDetailTableViewController


#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)loadMedicalNoteFromCoreDataWhenAPIFail{

    NSMutableArray *medicalNoteArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalNotes"];
    NSMutableArray *medicalNoteObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalNote;
    for (int index =0; index<medicalNoteObject.count; index++) {
        //get each patient in coredata
        medicalNote = [medicalNoteObject objectAtIndex:index];
        //onle load medical note that belong to selected medical record
        if ([[medicalNote valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",[self.selectedMedicalRecord objectForKey:@"Id"] ]]) {
            NSDictionary *medicalNoteDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [medicalNote valueForKey:@"medicalNoteID" ],@"Id",
                                        [medicalNote valueForKey:@"medicalRecordID" ],@"MedicalRecord",
                                        [medicalNote valueForKey:@"ownerID" ],@"Owner",
                                        [medicalNote valueForKey:@"creatorID" ],@"Creator",
                                        [medicalNote valueForKey:@"note" ],@"Note",
                                        [medicalNote valueForKey:@"time" ],@"Time",
                                        [medicalNote valueForKey:@"created" ],@"Created",
                                        [medicalNote valueForKey:@"lastModified" ],@"LastModified",
                                        nil];
            [medicalNoteArrayForFailAPI addObject:medicalNoteDic];
        }

    }

    self.medicalNoteArray = (NSArray*)medicalNoteArrayForFailAPI;
}


-(void)saveMedicalRecordNoteToCoreData{
    //get the medical record of specific patient which data was returned from API
    self.medicalNoteArray = [self.responseJSONData objectForKey:@"MedicalNotes"];
    //delete all the current medical Note of selected medical Record from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalNotes"];
    NSMutableArray *medicalNoteObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalNote;

    if (medicalNoteObject.count >0) {
        //delete the old medical note in the same medical record
        for (int index=0; index < medicalNoteObject.count; index++) {
            medicalNote = [medicalNoteObject objectAtIndex:index];
            if ([[medicalNote valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",[self.selectedMedicalRecord objectForKey:@"Id"] ]]) {
                [context deleteObject:medicalNote];//only delete medical Note that belong to selected Medical record
                NSLog(@"Delete Medical note success!");
            }

        }
    }

    for (int index =0; index < self.medicalNoteArray.count; index++) {
        NSDictionary *medicalNoteDic = [self.medicalNoteArray objectAtIndex:index];


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
}



#pragma mark - Connect to API function
-(void)getMedicalNoteFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];


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

    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Partner" :@"77",//[self.selectedMedicalRecord objectForKey:@"Owner"],
                              @"Mode":@"0",
                              @"Sort":@"1",
                              @"MedicalRecord":[self.selectedMedicalRecord objectForKey:@"Id"],
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];
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
                                                  [self saveMedicalRecordNoteToCoreData];
                                              }else{
                                                  [self loadMedicalNoteFromCoreDataWhenAPIFail];
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              [self loadMedicalNoteFromCoreDataWhenAPIFail];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self getMedicalNoteFromAPI];
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Medical Notes";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}

-(IBAction)addInfo:(id)sender{
    [self performSegueWithIdentifier:@"addMedicalNote" sender:self];
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

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.medicalNoteArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"medicalNoteCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"medicalNoteCell"];

    }
    // Configure the cell...
    NSDictionary *medicalNoteDic = self.medicalNoteArray[indexPath.row];
    NSString *time = [medicalNoteDic objectForKey:@"Time"];
    NSString *note = [medicalNoteDic objectForKey:@"Note"];

    NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];

    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]/1000];


    cell.textLabel.text = [dateFormatterToLocal stringFromDate: timeDate];
    cell.detailTextLabel.text =note;

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedMedicalNote = self.medicalNoteArray[indexPath.row];
    [self performSegueWithIdentifier:@"editMedicalNote" sender:self];

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
    if ([[segue identifier] isEqualToString:@"addMedicalNote"])
    {
        AddNewMedicalNoteViewController * addNewMedicalNoteViewcontroller = [segue destinationViewController];
        addNewMedicalNoteViewcontroller.selectedMedicalRecordId = [self.selectedMedicalRecord objectForKey:@"Id"];

    }
    if ([[segue identifier] isEqualToString:@"editMedicalNote"])
    {
        AddNewMedicalNoteViewController * addNewMedicalNoteViewcontroller = [segue destinationViewController];
        addNewMedicalNoteViewcontroller.selectedMedicalNote = self.selectedMedicalNote;

    }
}


@end
