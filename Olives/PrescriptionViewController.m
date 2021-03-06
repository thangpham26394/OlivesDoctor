//
//  PrescriptionViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/prescription/filter"
#import "PrescriptionViewController.h"
#import "MedicineTableViewController.h"
#import <CoreData/CoreData.h>
@interface PrescriptionViewController ()
@property (weak, nonatomic) IBOutlet UITableView *currentTableView;
@property (weak, nonatomic) IBOutlet UITableView *historyTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentController;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *prescriptionArray;
@property (strong,nonatomic) NSMutableArray *currentPrescription;
@property (strong,nonatomic) NSMutableArray *historyPrescription;
@property (strong,nonatomic) NSDictionary *selectedPrescription;
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;
@property(strong,nonatomic) NSMutableArray *cannotEditArray;
@property (assign,nonatomic)BOOL canEdit;
- (IBAction)changeSegment:(id)sender;

@end

@implementation PrescriptionViewController

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
        if ([[prescription valueForKey:@"ownerID"] isEqual:[NSString stringWithFormat:@"%@",self.selectedPatientID]]) {
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
            [prescriptionArrayForFailAPI addObject:prescriptionDic];
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
            if ([[prescription valueForKey:@"ownerID"] isEqual:[NSString stringWithFormat:@"%@",self.selectedPatientID]]) {
                [context deleteObject:prescription]; //only delete prescription that belong to selected patient
            }

        }
    }

    // insert new patients that gotten from API
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

-(void)loadPatienttDataFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Mode" :  @"0",
                              @"Sort" : @"1",
                              @"Direction":@"0",
                              @"Partner" :self.selectedPatientID
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
    self.navigationController.topViewController.title=@"Prescription";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] init];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
//    [rightBarButton setEnabled:NO];


    //start animation
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];

    [self loadPatienttDataFromAPI];
    [self.currentTableView reloadData];
    [self.historyTableView reloadData];

    //stop animation
    [self.activityIndicator stopAnimating];
    [self.backgroundView removeFromSuperview];


}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.currentTableView setHidden:NO];
    [self.historyTableView setHidden:YES];
    self.currentTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.historyTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.segmentController.tintColor = [UIColor colorWithRed:0/255.0 green:150/255.0 blue:136/255.0 alpha:1.0];
    self.cannotEditArray = [[NSMutableArray alloc]init];

    //set up for indicator view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.backgroundView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = CGPointMake(self.backgroundView .frame.size.width/2, self.backgroundView .frame.size.height/2);
    [self.backgroundView  addSubview:self.activityIndicator];
    self.currentWindow = [UIApplication sharedApplication].keyWindow;


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //check which prescriptions is current and which presctiption is history
    self.currentPrescription = [[NSMutableArray alloc]init];
    self.historyPrescription =[[NSMutableArray alloc]init];
    NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];

    for (int index =0; index <self.prescriptionArray.count; index ++) {
        NSDictionary *prescriptionDic = [self.prescriptionArray objectAtIndex:index];
        NSString *toString = [prescriptionDic objectForKey:@"To"];
        NSDate *toDate = [NSDate dateWithTimeIntervalSince1970:[toString doubleValue]/1000];
        NSDate *toDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:toDate]];
        NSTimeInterval toDateLocalTimInterval = [toDateLocal timeIntervalSince1970];

        //today date time with tim = 00:00:00:000
        NSDateFormatter * todayFormatter= [[NSDateFormatter alloc] init];
        [todayFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [todayFormatter setDateFormat:@"MM/dd/yyyy"];

        NSString *stringToday = [NSString stringWithFormat:@"%@ %@",[todayFormatter stringFromDate:[NSDate date] ] ,@"00:00:00:000"] ;
        NSDate *today = [dateFormatterToLocal dateFromString:stringToday];
        NSTimeInterval toDayLocalTimInterval = [today timeIntervalSince1970];

        if (toDateLocalTimInterval >= toDayLocalTimInterval) {
            [self.currentPrescription addObject:prescriptionDic];
        }else{
            [self.historyPrescription addObject:prescriptionDic];
        }
    }
    if (self.segmentController.selectedSegmentIndex ==0) {
        return self.currentPrescription.count; //return total current prescription
    }else{
        return self.historyPrescription.count; //return total history prescription
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    if (self.segmentController.selectedSegmentIndex ==0) {
        cell = [self.currentTableView dequeueReusableCellWithIdentifier:@"currentCell" forIndexPath:indexPath];

        NSString *prescriptioneName = [self.currentPrescription[indexPath.row] objectForKey:@"Name"];
        NSString *creator = [self.currentPrescription[indexPath.row]  objectForKey:@"Creator"];
        //check if current prescription is create by doctor or not
        NSString *currentDoctorID = [doctor valueForKey:@"doctorID"] ;
        if (![[NSString stringWithFormat:@"%@",creator] isEqual:[NSString stringWithFormat:@"%@",currentDoctorID]]) {
            cell.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
            [self.cannotEditArray addObject:[NSString stringWithFormat:@"%ld", (long)indexPath.row ]];
        }else{
            cell.backgroundColor = [UIColor whiteColor];
        }

        if ((id)prescriptioneName != [NSNull null]) {
            cell.textLabel.text = prescriptioneName;
        }else{
            cell.textLabel.text = @"no name";
        }

        cell.detailTextLabel.text = @"Details";
    }else{
        cell = [self.historyTableView dequeueReusableCellWithIdentifier:@"historyCell" forIndexPath:indexPath];

        NSString *prescriptioneName = [self.historyPrescription[indexPath.row] objectForKey:@"Name"];
        NSString *creator = [self.currentPrescription[indexPath.row]  objectForKey:@"Creator"];
        //check if current prescription is create by doctor or not
        NSString *currentDoctorID = [doctor valueForKey:@"doctorID"] ;
        if (![[NSString stringWithFormat:@"%@",creator] isEqual:[NSString stringWithFormat:@"%@",currentDoctorID]]) {
            cell.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
            [self.cannotEditArray addObject:[NSString stringWithFormat:@"%ld", (long)indexPath.row ]];
        }else{
            cell.backgroundColor = [UIColor whiteColor];
        }
        
        if ((id)prescriptioneName != [NSNull null]  && ![prescriptioneName isEqual:@"<null>"]) {
            cell.textLabel.text = prescriptioneName;
        }else{
            cell.textLabel.text = @"no name";
        }
        cell.detailTextLabel.text = @"Details";
    }


    // Configure the cell...
    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //check if current medical record can edit or not
    self.canEdit = YES;
    for (int index =0; index < self.cannotEditArray.count; index ++) {
        if ( [self.cannotEditArray containsObject: [NSString stringWithFormat:@"%ld",(long)indexPath.row]] ) {
            self.canEdit = NO;
        }
    }
    if (self.segmentController.selectedSegmentIndex ==0) {
        self.selectedPrescription = self.currentPrescription[indexPath.row];
        [self performSegueWithIdentifier:@"prescriptionShowDetail" sender:self];
        [self.currentTableView deselectRowAtIndexPath:indexPath animated:YES];
    }else{
        self.selectedPrescription = self.historyPrescription[indexPath.row];
        [self performSegueWithIdentifier:@"prescriptionShowDetail" sender:self];
        [self.currentTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}
- (IBAction)changeSegment:(id)sender {
    self.cannotEditArray = [[NSMutableArray alloc]init];
    switch (self.segmentController.selectedSegmentIndex)
    {
        case 0:
            [self.currentTableView setHidden:NO];
            [self.historyTableView setHidden:YES];
            [self.currentTableView reloadData];
            [self.historyTableView reloadData];
            break;
        case 1:
            [self.historyTableView setHidden:NO];
            [self.currentTableView setHidden:YES];
            [self.currentTableView reloadData];
            [self.historyTableView reloadData];
            break;
        default:
            break;
    }
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"prescriptionShowDetail"])
    {
        MedicineTableViewController * medicineTableViewcontroller = [segue destinationViewController];
        medicineTableViewcontroller.selectedPrescriptionID = [self.selectedPrescription objectForKey:@"Id"];
        medicineTableViewcontroller.canEdit = self.canEdit;
    }

    
}

@end
