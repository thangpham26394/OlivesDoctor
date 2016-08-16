//
//  PatientDetailsViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 6/25/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/experiment/filter"
#import "PatientDetailsViewController.h"
#import "ImportantInfoChartViewController.h"
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
@property (strong,nonatomic) NSDictionary *dictionaryForDisplay;
@property(strong,nonatomic) NSDictionary *selectedDataDic;
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;
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
                                           [experimentNote valueForKey:@"time" ],@"Time",
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
        NSString *time = [prescriptionDic objectForKey:@"Time"];

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
        [newExperiment setValue: [NSString stringWithFormat:@"%@", time] forKey:@"time"];

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
                              @"Mode" :  @"0",
                              @"Partner" :self.selectedPatientID,
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
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] init];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //start animation
    
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];


    //stop animation
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadExperimentNoteDataFromAPI];
            [self createShowAllDataArray];
            [self.importantInfoTableView reloadData];
            [self.activityIndicator stopAnimating];
            [self.backgroundView removeFromSuperview];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        });
    });



    //get all the experiment info and add to 1 dictionary self.experimentArray
}

-(void)createShowAllDataArray{

    NSMutableDictionary *dataDic = [[NSMutableDictionary alloc] init];
    for (int index=0; index < self.experimentArray.count; index ++) {
        NSDictionary *prescriptionDic = self.experimentArray[index];

        NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        [formatter setLocale:[NSLocale systemLocale]];
        [formatter setDateFormat:@"MM/dd/yyyy"];

        NSTimeInterval dateTimeInterval = [[prescriptionDic objectForKey:@"Time"] doubleValue]/1000;
        NSDate *createdDate = [NSDate dateWithTimeIntervalSince1970:dateTimeInterval];
        NSString *timeCreate = [formatter stringFromDate:createdDate];

        NSString *infoString = [prescriptionDic objectForKey:@"Info"];
        NSError *jsonError;
        NSData *objectData = [infoString dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *currentDic = [NSJSONSerialization JSONObjectWithData:objectData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&jsonError];

        //go throught every element of currentDic
        NSUInteger totalElement = [[currentDic allKeys] count];
        for (int i=0; i<totalElement; i++) {
            NSString *key = [[currentDic allKeys]objectAtIndex:i];
            NSString *value = [currentDic objectForKey:key];
            NSDictionary *dicValue = [NSDictionary dictionaryWithObjectsAndKeys:timeCreate,value, nil];//object is timecreated key is string value

            //check if this key is exist in dataDic or not
            if ([[dataDic allKeys] containsObject:key]) {
                //if this key already exist then get the mutable array value for key then add value into it
                NSMutableArray *dataDicArrayValue = [dataDic objectForKey:key];
                //check if dicValue is in the dataDicArrayvalue or not
                if (![dataDicArrayValue containsObject:dicValue]) {
                    [dataDicArrayValue addObject:dicValue]; //only add if there is no redundant value
                }

                [dataDic setObject:dataDicArrayValue forKey:key];
            }else{
                //if the key is new then create a value array content the value to become datadic value for key
                NSMutableArray *dataDicArrayValue = [[NSMutableArray alloc]init];
                [dataDicArrayValue addObject:dicValue];
                [dataDic setObject:dataDicArrayValue forKey:key];
            }
        }
    }
    self.dictionaryForDisplay = dataDic;

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

    //set up for indicator view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.center = CGPointMake(self.backgroundView .frame.size.width/2, self.backgroundView .frame.size.height/2);
    [self.backgroundView  addSubview:self.activityIndicator];
    self.currentWindow = [UIApplication sharedApplication].keyWindow;
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

    return [[self.dictionaryForDisplay allKeys] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"importantInfoCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:@"importantInfoCell"];

    }
    // Configure the cell...

    NSString *experimentName = [[self.dictionaryForDisplay allKeys] objectAtIndex:indexPath.row];
    cell.textLabel.text = experimentName;
    cell.detailTextLabel.text = @"details";

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    NSString *key = [[self.dictionaryForDisplay allKeys] objectAtIndex:indexPath.row];
    self.selectedDataDic =[NSDictionary dictionaryWithObjectsAndKeys:[self.dictionaryForDisplay objectForKey:key],key, nil] ;
    [self performSegueWithIdentifier:@"showChartView" sender:self];
    [self.importantInfoTableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showChartView"])
    {
        ImportantInfoChartViewController *importantChartView = [segue destinationViewController];
        importantChartView.displayDataDic = self.selectedDataDic;
    }
}


@end
