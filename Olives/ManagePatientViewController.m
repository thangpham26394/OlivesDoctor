//
//  ManagePatientViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/11/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/relationship/filter"
#import "ManagePatientViewController.h"
#import "CurrentPatientTableViewCell.h"
#import "WaitForAcceptTableViewCell.h"
#import "ViewDetailPatientInfoViewController.h"
#import <CoreData/CoreData.h>


@interface ManagePatientViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentcontroller;
@property (weak, nonatomic) IBOutlet UITableView *currentPatientView;
@property (weak, nonatomic) IBOutlet UITableView *waitingAcceptPatientView;
- (IBAction)segmentControllerAction:(id)sender;
- (IBAction)acceptAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)removeAction:(id)sender;

@property(strong,nonatomic) NSArray * waitForAcceptPatientArray;
@property(strong,nonatomic) NSArray * currentPatientArray;
@property(strong,nonatomic) NSArray * pendingPatientArray;
@property(strong,nonatomic) NSDictionary *selectedPatient;
@property (strong,nonatomic) NSDictionary *responseJSONData ;
@end

@implementation ManagePatientViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(NSArray *)loadPatientFromCoreData{

    NSMutableArray *patientArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
    NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *patient;
    for (int index =0; index<patientObject.count; index++) {
        //get each patient in coredata
        patient = [patientObject objectAtIndex:index];
        NSDictionary *patientDic = [NSDictionary dictionaryWithObjectsAndKeys:
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
        [patientArrayForFailAPI addObject:patientDic];
    }

    return (NSArray*)patientArrayForFailAPI;
}

#pragma handle API connection
-(void)loadPendingPatientDataFromAPI{

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
                              @"Status" :  @"0",
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
                                                  self.pendingPatientArray = [self.responseJSONData objectForKey:@"Relationships"];
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




#pragma mark view controller

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self loadPendingPatientDataFromAPI];
    [self.waitingAcceptPatientView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.currentPatientArray = [self loadPatientFromCoreData];
    if (self.isNotificationView) {
        self.segmentcontroller.selectedSegmentIndex = 1;
        [self.waitingAcceptPatientView setHidden:NO];
        [self.waitingAcceptPatientView reloadData];
    }
    self.pendingPatientArray = [[NSArray alloc]init];
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
    if (self.segmentcontroller.selectedSegmentIndex ==0) {
        return [self.currentPatientArray count];

    }else{
        return [self.pendingPatientArray count];
    }


}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    if (self.segmentcontroller.selectedSegmentIndex ==0) {
        CurrentPatientTableViewCell *cell = [self.currentPatientView dequeueReusableCellWithIdentifier:@"currentPatientCell" forIndexPath:indexPath];
        NSDictionary *patientDic = self.currentPatientArray[indexPath.row];

        //config cell
        NSData *data = [patientDic objectForKey:@"Photo"];
        UIImage *img = [[UIImage alloc] initWithData:data];
        cell.avatar.image = img; //set avatar

        cell.nameLabel.text = [NSString stringWithFormat:@"%@%@", [patientDic objectForKey:@"FirstName"] ,[patientDic objectForKey:@"LastName"] ];
        
        
        return cell;
    }else{
        NSDictionary *pendingDic = [self.pendingPatientArray objectAtIndex:indexPath.row];
        WaitForAcceptTableViewCell *cell = [self.waitingAcceptPatientView dequeueReusableCellWithIdentifier:@"watForAcceptCell" forIndexPath:indexPath];

        //config cell
        NSDictionary *pendingPatientDic = [pendingDic objectForKey:@"Source"];
        NSString *imageURL = [pendingPatientDic objectForKey:@"Photo"];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL] ];
        UIImage *img = [[UIImage alloc] initWithData:data];

        cell.patientAvatar.image = img; //set avatar
        cell.nameLabel.text = [NSString stringWithFormat:@"%@%@", [pendingPatientDic objectForKey:@"FirstName"] ,[pendingPatientDic objectForKey:@"LastName"] ];

        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected

    if (self.segmentcontroller.selectedSegmentIndex ==0) {
        // if the view current state is not for add new appointment
        self.selectedPatient = self.currentPatientArray[indexPath.row];
        [self performSegueWithIdentifier:@"showPatientInfo" sender:self];
        [self.currentPatientView deselectRowAtIndexPath:indexPath animated:YES];
        [self.currentPatientView reloadData];
    }else{
        self.selectedPatient = self.pendingPatientArray[indexPath.row];
        [self performSegueWithIdentifier:@"showPatientInfo" sender:self];
        [self.waitingAcceptPatientView deselectRowAtIndexPath:indexPath animated:YES];
    }


}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if (self.segmentcontroller.selectedSegmentIndex ==0) {
        if ([[segue identifier] isEqualToString:@"showPatientInfo"])
        {
            ViewDetailPatientInfoViewController *detailPatientInfo = [segue destinationViewController];
            detailPatientInfo.selectedPatient = self.selectedPatient;
        }
    }else{
        if ([[segue identifier] isEqualToString:@"showPatientInfo"])
        {
            ViewDetailPatientInfoViewController *detailPatientInfo = [segue destinationViewController];
            detailPatientInfo.selectedPatient = self.selectedPatient;
        }
    }

}


- (IBAction)segmentControllerAction:(id)sender {

    switch (self.segmentcontroller.selectedSegmentIndex)
    {
        case 0:
            [self.waitingAcceptPatientView setHidden:YES];
            [self.currentPatientView reloadData];
            break;
        case 1:
            [self.waitingAcceptPatientView setHidden:NO];
            [self.waitingAcceptPatientView reloadData];
            break;
        default:
            break;
    }
}

- (IBAction)acceptAction:(id)sender {
    NSLog(@"accept");
}

- (IBAction)cancelAction:(id)sender {
    NSLog(@"cancel");
}

- (IBAction)removeAction:(id)sender {
    NSLog(@"remove");
}
@end
