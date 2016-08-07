//
//  PatientDetailsViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 6/25/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/experiment/filter"
#import "PatientDetailsViewController.h"
#import <CoreData/CoreData.h>
@interface PatientDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;
@property (weak, nonatomic) IBOutlet UITableView *importantInfoTableView;
@property (weak, nonatomic) IBOutlet UILabel *patientName;
@property (weak, nonatomic) IBOutlet UILabel *patientPhone;
@property (weak, nonatomic) IBOutlet UILabel *patientAddress;
@property (weak, nonatomic) IBOutlet UILabel *patientEmail;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *experimentArray;

@end

@implementation PatientDetailsViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)loadMedicalExperimentFromCoreDataWhenAPIFail{
    NSMutableArray *experimentArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ExperimentNotes"];
    NSMutableArray *experimentNoteObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *experimentNote;
    for (int index =0; index<experimentNoteObject.count; index++) {
        //get each patient in coredata
        experimentNote = [experimentNoteObject objectAtIndex:index];
        if ([[experimentNote valueForKey:@"ownerID"] isEqual:self.selectedPatientID]) {
            NSDictionary *experimentDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [experimentNote valueForKey:@"id" ],@"Id",
                                           [experimentNote valueForKey:@"medicalRecordID"],@"MedicalRecord",
                                           [experimentNote valueForKey:@"ownerID" ],@"Owner",
                                           [experimentNote valueForKey:@"creatorID" ],@"Creator",
                                           [experimentNote valueForKey:@"name" ],@"Name",
                                           [experimentNote valueForKey:@"info" ],@"Info",
                                           [experimentNote valueForKey:@"createdDate" ],@"Created",
                                           [experimentNote valueForKey:@"lastModified" ],@"LastModified",
                                           nil];
            [experimentArrayForFailAPI addObject:experimentDic];
        }

    }
    self.experimentArray = (NSArray*)experimentArrayForFailAPI;

}

-(void)saveMedicalExperimentToCoreData{
    self.experimentArray = [self.responseJSONData objectForKey:@"ExperimentNotes"];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ExperimentNotes"];
    NSMutableArray *experimentNoteObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *experimentNote;
    //delete previous prescription
    if (experimentNoteObject.count >0) {

        for (int index=0; index < experimentNoteObject.count; index++) {
            experimentNote = [experimentNoteObject objectAtIndex:index];
            if ([[experimentNote valueForKey:@"ownerID"] isEqual:[NSString stringWithFormat:@"%@",self.selectedPatientID]]) {
                [context deleteObject:experimentNote];//only delete the experiment note that belong to selected patient
            }

        }
    }

    // insert new patients that gotten from API
    for (int index = 0; index < self.experimentArray.count; index++) {
        NSDictionary *prescriptionDic = self.experimentArray[index];

        NSString *experimentID = [prescriptionDic objectForKey:@"Id"];
        NSString *medicalRecord = [prescriptionDic objectForKey:@"MedicalRecord"];
        NSString *owner = [prescriptionDic objectForKey:@"Owner"];
        NSString *creator = [prescriptionDic objectForKey:@"Creator"];
        NSString *name = [prescriptionDic objectForKey:@"Name"];
        NSString *info = [prescriptionDic objectForKey:@"Info"];
        NSString *createdDate = [prescriptionDic objectForKey:@"Created"];
        NSString *lastModified = [prescriptionDic objectForKey:@"LastModified"];


        //create new patient object
        NSManagedObject *newExperiment = [NSEntityDescription insertNewObjectForEntityForName:@"ExperimentNotes" inManagedObjectContext:context];
        //set value for each attribute of new patient before save to core data
        [newExperiment setValue: [NSString stringWithFormat:@"%@", experimentID] forKey:@"id"];
        [newExperiment setValue: [NSString stringWithFormat:@"%@", medicalRecord] forKey:@"medicalRecordID"];
        [newExperiment setValue: [NSString stringWithFormat:@"%@", owner] forKey:@"ownerID"];
        [newExperiment setValue: [NSString stringWithFormat:@"%@", creator] forKey:@"creatorID"];
        [newExperiment setValue: [NSString stringWithFormat:@"%@", name] forKey:@"name"];
        [newExperiment setValue: [NSString stringWithFormat:@"%@", info] forKey:@"info"];
        [newExperiment setValue: [NSString stringWithFormat:@"%@", createdDate] forKey:@"createdDate"];
        [newExperiment setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"lastModified"];


        NSError *error = nil;
        // Save the object to persistent store
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save Experiment Note success!");
        }
    }
}


#pragma mark - Connect to API function

-(void)loadExperimentNoteDataFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Mode" :  @"0"
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
                                                  [self saveMedicalExperimentToCoreData];
                                              }else{
                                                  [self loadMedicalExperimentFromCoreDataWhenAPIFail];
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              //self.patientArray = [self loadPatientFromCoreDataWhenAPIFail];
                                              [self loadMedicalExperimentFromCoreDataWhenAPIFail];
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
    self.navigationController.topViewController.title=@"Patient Details";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self loadExperimentNoteDataFromAPI];
    [self.importantInfoTableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"TTTTTTTTTTTTTTTTTTTTTT        %@",self.selectedPatientID);
    //get patient infor from coredata with sent id
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
    NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *patient;
    for (int index = 0; index<patientObject.count; index++) {
        patient = [patientObject objectAtIndex:index];
        if ([[patient valueForKey:@"patientId"] isEqual:self.selectedPatientID]) {
            break;
        }
    }
    self.avatarImage.image = [UIImage imageWithData:[patient valueForKey:@"photo"]];
    self.patientName.text = [NSString stringWithFormat:@"%@ %@",[patient valueForKey:@"firstName"],[patient valueForKey:@"lastName"]];
    self.patientPhone.text = [patient valueForKey:@"phone"];
    self.patientAddress.text = [patient valueForKey:@"address"];
    self.patientEmail.text = [patient valueForKey:@"email"];

    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width / 2;
    self.avatarImage.clipsToBounds = YES;
    self.importantInfoTableView.layer.cornerRadius = 5;
    self.importantInfoTableView.clipsToBounds = YES;
    self.sendMessageButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:153/255.0 blue:153/255.0 alpha:1.0];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)addInfo:(id)sender{
    NSLog(@"important info add");
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.experimentArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"importantInfoCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:@"importantInfoCell"];

    }
    // Configure the cell...

    NSDictionary *experimentDic = [self.experimentArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [experimentDic objectForKey:@"Name"];
    cell.detailTextLabel.text = @"details";

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    [self performSegueWithIdentifier:@"showChartView" sender:self];

    [self.importantInfoTableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
