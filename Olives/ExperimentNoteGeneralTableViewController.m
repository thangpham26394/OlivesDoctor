//
//  ExperimentNoteGeneralTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/experiment/filter"
#define APIURLADD @"http://olive.azurewebsites.net/api/medical/experiment"
#import "ExperimentNoteGeneralTableViewController.h"
#import "MedicalRecordExperimentNoteTableViewController.h"
#import <CoreData/CoreData.h>

@interface ExperimentNoteGeneralTableViewController ()
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *experimentArray;
@property (strong,nonatomic) NSDictionary *selectedExperimentNote;
@property(strong,nonatomic) UIView *popupView;
@property(strong,nonatomic) UITextField *stringTextField;
@property(strong,nonatomic) UIDatePicker *experimentDatePicker;
@end

@implementation ExperimentNoteGeneralTableViewController


#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)saveNewExperimentNoteToCoreData{
    NSDictionary *noteDic = [self.responseJSONData objectForKey:@"Note"];

    NSManagedObjectContext *context = [self managedObjectContext];
    NSString *experimentID = [noteDic objectForKey:@"Id"];
    NSString *medicalRecord = [noteDic objectForKey:@"MedicalRecord"];
    NSString *owner = [noteDic objectForKey:@"Owner"];
    NSString *name = [noteDic objectForKey:@"Name"];
    NSString *info = [noteDic objectForKey:@"Info"];
    NSString *createdDate = [noteDic objectForKey:@"Created"];



    //create new patient object
    NSManagedObject *newExperiment = [NSEntityDescription insertNewObjectForEntityForName:@"ExperimentNotes" inManagedObjectContext:context];
    //set value for each attribute of new patient before save to core data
    [newExperiment setValue: [NSString stringWithFormat:@"%@", experimentID] forKey:@"id"];
    [newExperiment setValue: [NSString stringWithFormat:@"%@", medicalRecord] forKey:@"medicalRecordID"];
    [newExperiment setValue: [NSString stringWithFormat:@"%@", owner] forKey:@"ownerID"];
    [newExperiment setValue: [NSString stringWithFormat:@"%@", name] forKey:@"name"];
    [newExperiment setValue: [NSString stringWithFormat:@"%@", info] forKey:@"info"];
    [newExperiment setValue: [NSString stringWithFormat:@"%@", createdDate] forKey:@"createdDate"];



    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save New Experiment Note success!");
    }

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
            if ([[experimentNote valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",self.medicalRecordID]]) {
                [context deleteObject:experimentNote];//only delete the experiment note that belong to selected medical record
            }

        }
    }

    // insert new patients that gotten from API
    for (int index = 0; index < self.experimentArray.count; index++) {
        NSDictionary *experimentNoteDic = self.experimentArray[index];

        NSString *experimentID = [experimentNoteDic objectForKey:@"Id"];
        NSString *medicalRecord = [experimentNoteDic objectForKey:@"MedicalRecord"];
        NSString *owner = [experimentNoteDic objectForKey:@"Owner"];
        NSString *creator = [experimentNoteDic objectForKey:@"Creator"];
        NSString *name = [experimentNoteDic objectForKey:@"Name"];
        NSString *info = [experimentNoteDic objectForKey:@"Info"];
        NSString *createdDate = [experimentNoteDic objectForKey:@"Created"];
        NSString *lastModified = [experimentNoteDic objectForKey:@"LastModified"];
        NSString *time = [experimentNoteDic objectForKey:@"Time"];

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

-(void)loadMedicalExperimentFromCoreDataWhenAPIFail{
    NSMutableArray *experimentArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ExperimentNotes"];
    NSMutableArray *experimentNoteObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *experimentNote;
    for (int index =0; index<experimentNoteObject.count; index++) {
        experimentNote = [experimentNoteObject objectAtIndex:index];

        //only get experiment note belong to selected medical record
        if ([[experimentNote valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",self.medicalRecordID]]) {
            NSDictionary *experimentDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [experimentNote valueForKey:@"id" ],@"Id",
                                           [experimentNote valueForKey:@"medicalRecordID"],@"MedicalRecord",
                                           [experimentNote valueForKey:@"ownerID" ],@"Owner",
                                           [experimentNote valueForKey:@"name" ],@"Name",
                                           [experimentNote valueForKey:@"info" ],@"Info",
                                           [experimentNote valueForKey:@"createdDate" ],@"Created",
                                           [experimentNote valueForKey:@"creatorID" ],@"Creator",
                                           [experimentNote valueForKey:@"lastModified" ],@"LastModified",
                                           [experimentNote valueForKey:@"time" ],@"Time",
                                           nil];
            [experimentArrayForFailAPI addObject:experimentDic];
        }

    }
    self.experimentArray = (NSArray*)experimentArrayForFailAPI;

}

#pragma mark - Connect to API function
-(void)addNewExperimentNoteAPIWithName:(NSString*)experimentNoteName{

    // create url
    NSURL *url = [NSURL URLWithString:APIURLADD];
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
    // dateformater to convert to UTC time zone
    NSDateFormatter *dateFormaterToUTC = [[NSDateFormatter alloc] init];
    dateFormaterToUTC.timeStyle = NSDateFormatterNoStyle;
    dateFormaterToUTC.dateFormat = @"MM/dd/yyyy HH:mm:ss:SSS";
    [dateFormaterToUTC setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSDate *setDate = self.experimentDatePicker.date;
    NSDate *convertDate = [dateFormaterToUTC dateFromString:[dateFormaterToUTC stringFromDate:setDate]];
    NSTimeInterval experimentTimeInterval = [convertDate timeIntervalSince1970];
    NSDictionary *account = @{
                              @"Name":experimentNoteName,
                              @"MedicalRecord":self.medicalRecordID,
                              @"Time":[NSString stringWithFormat:@"%f",experimentTimeInterval*1000],
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
                                                  [self saveNewExperimentNoteToCoreData];
                                                  [self loadMedicalExperimentFromCoreDataWhenAPIFail];
                                                  [self.tableView reloadData];
                                              }else{
                                              }

                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSError *parsJSONError = nil;
                                              if (data ==nil) {
                                                  UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Internet Error"
                                                                                                                 message:nil
                                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                                  UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                     style:UIAlertActionStyleDefault
                                                                                                   handler:^(UIAlertAction * action) {}];
                                                  [alert addAction:OKAction];
                                                  [self presentViewController:alert animated:YES completion:nil];
                                                  dispatch_semaphore_signal(sem);

                                                  return;
                                              }
                                              NSDictionary *errorDic = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              NSArray *errorArray = [errorDic objectForKey:@"Errors"];
                                              //                                              NSLog(@"\n\n\nError = %@",[errorArray objectAtIndex:0]);

                                              UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                                             message:[errorArray objectAtIndex:0]
                                                                                                      preferredStyle:UIAlertControllerStyleAlert];

                                              UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                 style:UIAlertActionStyleDefault
                                                                                               handler:^(UIAlertAction * action) {}];
                                              [alert addAction:OKAction];
                                              [self presentViewController:alert animated:YES completion:nil];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}
-(void)loadExperimentNoteDataFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Mode" :  @"0",
                              @"MedicalRecord" :  self.medicalRecordID,
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

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self loadExperimentNoteDataFromAPI];
    [self.tableView reloadData];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Experiment Notes";
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
    // show popup view here
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;


    self.popupView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.popupView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];

    UIView *myView = [[UIView alloc]initWithFrame:CGRectMake(20, 150, screenWidth-40, 280)];
    myView.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    myView.layer.cornerRadius = 10.0f;

    //create OK button
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth-40)/2,240, (screenWidth-40)/2, 40)];
    okButton.backgroundColor = [UIColor whiteColor];
    [okButton setTitle: @"OK" forState: UIControlStateNormal];
    [okButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    [okButton setTitleColor:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0] forState:UIControlStateNormal];

    UIBezierPath *maskPathOK = [UIBezierPath bezierPathWithRoundedRect:okButton.bounds byRoundingCorners:(UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayerOK = [[CAShapeLayer alloc] init];
    maskLayerOK.frame = self.popupView.bounds;
    maskLayerOK.path  = maskPathOK.CGPath;
    okButton.layer.mask = maskLayerOK;
    [okButton addTarget:self action:@selector(okButtonActionHightLight:) forControlEvents:UIControlEventTouchDown];
    [okButton addTarget:self action:@selector(okButtonActionNormal:) forControlEvents:UIControlEventTouchUpInside];



    //create cancel button
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0,240, (screenWidth-40)/2-1, 40)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton setTitle: @"Cancel" forState: UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0]];
    [cancelButton setTitleColor:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0] forState:UIControlStateNormal];

    UIBezierPath *maskPathCancel = [UIBezierPath bezierPathWithRoundedRect:cancelButton.bounds byRoundingCorners:(UIRectCornerBottomLeft) cornerRadii:CGSizeMake(10.0, 10.0)];

    CAShapeLayer *maskLayerCancel = [[CAShapeLayer alloc] init];
    maskLayerCancel.frame = self.popupView.bounds;
    maskLayerCancel.path  = maskPathCancel.CGPath;
    cancelButton.layer.mask = maskLayerCancel;
    [cancelButton addTarget:self action:@selector(cancelButtonActionHightLight:) forControlEvents:UIControlEventTouchDown];
    [cancelButton addTarget:self action:@selector(cancelButtonActionNormal:) forControlEvents:UIControlEventTouchUpInside];


    //Title Label
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,20, (screenWidth-40), 40)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0]];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleLabel setTextColor:[UIColor blackColor]];
    titleLabel.text = @"Add new experiment note";

    //top content View
    UIView *topContentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth-40, 239)];
    topContentView.backgroundColor = [UIColor whiteColor];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:topContentView.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.popupView.bounds;
    maskLayer.path  = maskPath.CGPath;
    topContentView.layer.mask = maskLayer;

    //text Field for string
    self.stringTextField = [[UITextField alloc]initWithFrame:CGRectMake(70, 100, screenWidth-130, 30)];
    [self.stringTextField  setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    self.stringTextField .layer.cornerRadius = 5.0f;




    //name Label
    UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(10,100, 50, 30)];
    [nameLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15.0]];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [nameLabel setTextColor:[UIColor blackColor]];
    nameLabel.text = @"Name";


    //name Label
    UILabel *timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(10,140, 50, 30)];
    [timeLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15.0]];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    [timeLabel setTextColor:[UIColor blackColor]];
    timeLabel.text = @"Time";

    self.experimentDatePicker = [[UIDatePicker alloc]initWithFrame:CGRectMake(10,165, screenWidth-80, 60)];
    self.experimentDatePicker.datePickerMode = UIDatePickerModeDate;


    [topContentView addSubview:timeLabel];
    [topContentView addSubview:self.experimentDatePicker];
    [topContentView addSubview:titleLabel];
    [topContentView addSubview:self.stringTextField ];
    [topContentView addSubview:nameLabel];
    [myView addSubview:topContentView];
    [myView addSubview:okButton];
    [myView addSubview:cancelButton];

    [self.popupView addSubview:myView];
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self.popupView];

}
//action to change background color only
-(IBAction)okButtonActionHightLight:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor lightGrayColor];
}
-(IBAction)cancelButtonActionHightLight:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor lightGrayColor];
}

//action to call to add or update api
-(IBAction)okButtonActionNormal:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor whiteColor];
    [self.stringTextField resignFirstResponder];
    [self addNewExperimentNoteAPIWithName:self.stringTextField.text];
    [UIView animateWithDuration:0.5
                     animations:^{self.popupView .alpha = 0.0;}
                     completion:^(BOOL finished){ [self.popupView removeFromSuperview]; }];
}
//dissmiss popup view
-(IBAction)cancelButtonActionNormal:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor whiteColor];
    [self.stringTextField resignFirstResponder];
    NSLog(@"Cancel ACtion");
    [UIView animateWithDuration:0.5
                     animations:^{self.popupView .alpha = 0.0;}
                     completion:^(BOOL finished){ [self.popupView removeFromSuperview]; }];
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

    return self.experimentArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"experimentNoteCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:@"experimentNoteCell"];

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
    self.selectedExperimentNote = [self.experimentArray objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"showInfoExperimentNote" sender:self];

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

    if ([[segue identifier] isEqualToString:@"showInfoExperimentNote"])
    {
        MedicalRecordExperimentNoteTableViewController *medicalRecordExperimentNote= [segue destinationViewController];
        medicalRecordExperimentNote.experimentNoteID = [self.selectedExperimentNote objectForKey:@"Id"];
        medicalRecordExperimentNote.canEdit = self.canEdit;
    }

}


@end
