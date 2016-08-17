//
//  ManagePatientViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/11/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL_PENDING @"http://olive.azurewebsites.net/api/relationship/request/filter"
#define APIURL_CURRENT @"http://olive.azurewebsites.net/api/relationship/filter"
#define APIURL_ACCEPT @"http://olive.azurewebsites.net/api/relationship/request/confirm?Id="
#define APIURL_REMOVE @"http://olive.azurewebsites.net/api/relationship?Id="
#define APIURL_CANCEL @"http://olive.azurewebsites.net/api/relationship/request?Id="



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
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;
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

//-(NSArray *)loadPatientFromCoreData{
//
//    NSMutableArray *patientArrayForFailAPI = [[NSMutableArray alloc]init];
//    NSManagedObjectContext *context = [self managedObjectContext];
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
//    NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
//    NSManagedObject *patient;
//    for (int index =0; index<patientObject.count; index++) {
//        //get each patient in coredata
//        patient = [patientObject objectAtIndex:index];
//        NSDictionary *patientDic = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    [patient valueForKey:@"patientId" ],@"Id",
//                                    [patient valueForKey:@"firstName" ],@"FirstName",
//                                    [patient valueForKey:@"lastName" ],@"LastName",
//                                    [patient valueForKey:@"birthday" ],@"Birthday",
//                                    [patient valueForKey:@"phone" ],@"Phone",
//                                    [patient valueForKey:@"photo" ],@"Photo",
//                                    [patient valueForKey:@"address" ],@"Address",
//                                    [patient valueForKey:@"email" ],@"Email",
//                                    [patient valueForKey:@"weight" ],@"Weight",
//                                    [patient valueForKey:@"height" ],@"Height",
//                                    nil];
//        [patientArrayForFailAPI addObject:patientDic];
//    }
//
//    return (NSArray*)patientArrayForFailAPI;
//}

#pragma mark handle API connection

-(void)removePatientAPIWithID:(NSString*)patientID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURL_REMOVE,patientID]];
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
    [urlRequest setHTTPMethod:@"DELETE"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
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
                                              self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONData != nil) {
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


-(void)cancelRequestAPIWithID:(NSString*)patientID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURL_CANCEL,patientID]];
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
    [urlRequest setHTTPMethod:@"DELETE"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
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
                                              self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONData != nil) {
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








-(void)acceptRequestAPIWithID:(NSString*)requestID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURL_ACCEPT,requestID]];
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
    [urlRequest setHTTPMethod:@"PUT"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
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
                                              self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONData != nil) {
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


-(void)loadCurrentPatientDataFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL_CURRENT];
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
                                                  self.currentPatientArray = [self.responseJSONData objectForKey:@"Relationships"];
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



-(void)loadPendingPatientDataFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL_PENDING];
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
                                                  self.pendingPatientArray = [self.responseJSONData objectForKey:@"RelationshipRequests"];
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

    //start animation
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];

    [self loadPendingPatientDataFromAPI];
    [self loadCurrentPatientDataFromAPI];
    [self.waitingAcceptPatientView reloadData];
    [self.currentPatientView reloadData];

    //stop animation
    [self.activityIndicator stopAnimating];
    [self.backgroundView removeFromSuperview];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.currentPatientArray = [self loadPatientFromCoreData];
    self.segmentcontroller.tintColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];
    if (self.isNotificationView) {
        self.segmentcontroller.selectedSegmentIndex = 1;
        [self.waitingAcceptPatientView setHidden:NO];
        [self.waitingAcceptPatientView reloadData];
    }
    self.pendingPatientArray = [[NSArray alloc]init];

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
        NSDictionary *currentDic = self.currentPatientArray[indexPath.row];

        //config cell
        NSDictionary *currentPatientDic = [currentDic objectForKey:@"Source"];
        NSString *imageURL = [currentPatientDic objectForKey:@"Photo"];
        NSData *data ;
        
        if ((id)imageURL != [NSNull null])  {
            NSURL *url = [NSURL URLWithString:imageURL];
            data = [NSData dataWithContentsOfURL:url];
        }else{
            data = UIImagePNGRepresentation([UIImage imageNamed:@"nullAvatar"]);
        }

        UIImage *img = [[UIImage alloc] initWithData:data];

        cell.avatar.image = img; //set avatar
        [cell.removeButton addTarget:self action:@selector(removeAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.removeButton.tag = indexPath.row;
        cell.nameLabel.text = [NSString stringWithFormat:@"%@%@", [currentPatientDic objectForKey:@"FirstName"] ,[currentPatientDic objectForKey:@"LastName"] ];
        
        
        return cell;
    }else{
        NSDictionary *pendingDic = [self.pendingPatientArray objectAtIndex:indexPath.row];
        WaitForAcceptTableViewCell *cell = [self.waitingAcceptPatientView dequeueReusableCellWithIdentifier:@"watForAcceptCell" forIndexPath:indexPath];

        //config cell
        NSDictionary *pendingPatientDic = [pendingDic objectForKey:@"Source"];
        NSString *imageURL = [pendingPatientDic objectForKey:@"Photo"];
        NSData *data ;

        if ((id)imageURL != [NSNull null])  {
            NSURL *url = [NSURL URLWithString:imageURL];
            data = [NSData dataWithContentsOfURL:url];
        }else{
            data = UIImagePNGRepresentation([UIImage imageNamed:@"nullAvatar"]);
        }

        UIImage *img = [[UIImage alloc] initWithData:data];

        cell.patientAvatar.image = img; //set avatar
        cell.nameLabel.text = [NSString stringWithFormat:@"%@%@", [pendingPatientDic objectForKey:@"FirstName"] ,[pendingPatientDic objectForKey:@"LastName"] ];
        [cell.acceptButton addTarget:self action:@selector(acceptAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.acceptButton.tag = indexPath.row;
        [cell.cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.cancelButton.tag = indexPath.row;
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
            detailPatientInfo.currentPatientID = [[self.selectedPatient objectForKey:@"Source"] objectForKey:@"Id"];
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
    NSDictionary *pendingDic = [self.pendingPatientArray objectAtIndex:[sender tag]];

    //start animation
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];

    [self acceptRequestAPIWithID:[pendingDic objectForKey:@"Id"]];
    [self loadPendingPatientDataFromAPI];
    [self loadCurrentPatientDataFromAPI];
    [self.waitingAcceptPatientView reloadData];
    [self.currentPatientView reloadData];

    //stop animation
    [self.activityIndicator stopAnimating];
    [self.backgroundView removeFromSuperview];

}

- (IBAction)cancelAction:(id)sender {
    NSLog(@"cancel");
    NSDictionary *pendingDic = [self.pendingPatientArray objectAtIndex:[sender tag]];
    NSString *patientId = [pendingDic objectForKey:@"Id"];
    [self showConfirmAlertForCancel:patientId];
}

- (IBAction)removeAction:(id)sender {
//    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:[sender tag]];
    NSLog(@"remove %ld",(long)[sender tag]);
    NSDictionary *currentDic = [self.currentPatientArray objectAtIndex:[sender tag]];
    NSString *patientId = [currentDic objectForKey:@"Id"];
    [self showConfirmAlertForRemove:patientId];

}

-(void)showConfirmAlertForCancel:(NSString *)patientID{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                                                   message:@"This request will be cancel!"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         //start animation
                                                         [self.currentWindow addSubview:self.backgroundView];
                                                         [self.activityIndicator startAnimating];

                                                         [self cancelRequestAPIWithID:patientID];
                                                         [self loadPendingPatientDataFromAPI];
                                                         [self loadCurrentPatientDataFromAPI];
                                                         [self.waitingAcceptPatientView reloadData];
                                                         [self.currentPatientView reloadData];
                                                         
                                                         //stop animation
                                                         [self.activityIndicator stopAnimating];
                                                         [self.backgroundView removeFromSuperview];


                                                     }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                         }];
    [alert addAction:OKAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showConfirmAlertForRemove:(NSString *)patientID{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                                                   message:@"This patient will be removed!"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {

                                                         //start animation
                                                         [self.currentWindow addSubview:self.backgroundView];
                                                         [self.activityIndicator startAnimating];

                                                         [self removePatientAPIWithID:patientID];
                                                         [self loadPendingPatientDataFromAPI];
                                                         [self loadCurrentPatientDataFromAPI];
                                                         [self.waitingAcceptPatientView reloadData];
                                                         [self.currentPatientView reloadData];

                                                         //stop animation
                                                         [self.activityIndicator stopAnimating];
                                                         [self.backgroundView removeFromSuperview];


                                                     }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                         }];
    [alert addAction:OKAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
