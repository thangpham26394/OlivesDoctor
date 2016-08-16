//
//  HomeViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 6/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define API_NOTIFICATION_URL @"http://olive.azurewebsites.net/api/notification/filter"
#define API_NOTIFICATION_PUT_URL @"http://olive.azurewebsites.net/api/notification/seen"

#define API_MESSAGE_URL @"http://olive.azurewebsites.net/api/message/filter"
#define API_MESSAGE_PUT_URL @"http://olive.azurewebsites.net/api/message/seen"

#import "HomeViewController.h"
#import "SWRevealViewController.h"
#import "SignalR.h"
#import "ShowNotificationTableViewController.h"
#import "ManagePatientViewController.h"
#import "PatientsTableViewController.h"
#import <CoreData/CoreData.h>

@interface HomeViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *messageNotiView;
@property (weak, nonatomic) IBOutlet UIView *patientRequestNotiView;
@property (weak, nonatomic) IBOutlet UIView *appointmentNotiView;
@property (weak, nonatomic) IBOutlet UIView *serviceNotiView;
@property (weak, nonatomic) IBOutlet UIImageView *messageImage;
@property (weak, nonatomic) IBOutlet UIImageView *patientRequestImage;
@property (weak, nonatomic) IBOutlet UIImageView *appointmentImage;
@property (weak, nonatomic) IBOutlet UIImageView *serviceImage;
@property (strong,nonatomic) NSMutableArray *appointmentNotiArray;
@property (strong,nonatomic) NSMutableArray *medicalNotiArray;
@property (strong,nonatomic) NSMutableArray *messageNotiArray;
@property (strong,nonatomic) NSMutableArray *requestlNotiArray;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *notificationArray;
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;

@end

@implementation HomeViewController
- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}


#pragma mark - Connect to API function

-(void)putSeenNotificationDataToAPIWithTopic:(NSArray *) topic{

    // create url
    NSURL *url = [NSURL URLWithString:API_NOTIFICATION_PUT_URL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];


    //    sessionConfig.timeoutIntervalForRequest = 5.0;
    //    sessionConfig.timeoutIntervalForResource = 5.0;

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
    [urlRequest setTimeoutInterval:10];

    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Topics" :  topic,
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

-(void)putSeenMessageDataToAPIWithTopic:(NSArray *) topic{

    // create url
    NSURL *url = [NSURL URLWithString:API_MESSAGE_PUT_URL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    sessionConfig.timeoutIntervalForRequest = 5.0;
    //    sessionConfig.timeoutIntervalForResource = 5.0;

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
    [urlRequest setTimeoutInterval:10];

    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Partner" :  topic,
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


-(void)loadMessageDataFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:API_MESSAGE_URL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    sessionConfig.timeoutIntervalForRequest = 5.0;
    //    sessionConfig.timeoutIntervalForResource = 5.0;

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
    [urlRequest setTimeoutInterval:5];
    NSDictionary *account = @{
                              @"IsSeen":@"false",
                              @"Sort":@"0",
                              @"Mode":@"1"
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
                                                  self.messageNotiArray = [self.responseJSONData objectForKey:@"Messages"];
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      self.badgeMessageLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.messageNotiArray.count ];

                                                  });
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


-(void)loadNotificationDataFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:API_NOTIFICATION_URL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
//    sessionConfig.timeoutIntervalForRequest = 5.0;
//    sessionConfig.timeoutIntervalForResource = 5.0;

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
    [urlRequest setTimeoutInterval:5];
    NSDictionary *account = @{
                              @"IsSeen":@"false",
                              @"Sort":@"0",
                              @"Mode":@"1"
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
                                                  [self allocateNotificationToView];
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

-(void)allocateNotificationToView{
    self.notificationArray = [self.responseJSONData objectForKey:@"Notifications"];

    self.appointmentNotiArray = [[NSMutableArray alloc]init];
    self.medicalNotiArray = [[NSMutableArray alloc] init];
    self.requestlNotiArray = [[NSMutableArray alloc] init];

    for (int index =0; index<self.notificationArray.count; index++) {
        NSDictionary *currentNotiDic = self.notificationArray[index];
        //check if current noti is belong to which subview
        if ([[NSString stringWithFormat:@"%@", [currentNotiDic objectForKey:@"Topic"] ]  isEqual:@"0"] ) {
            [self.appointmentNotiArray addObject:currentNotiDic];
        }else if ([[NSString stringWithFormat:@"%@", [currentNotiDic objectForKey:@"Topic"] ]  isEqual:@"7"] ){
            [self.requestlNotiArray addObject:currentNotiDic];
        }
        else{
            [self.medicalNotiArray addObject:currentNotiDic];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.badgeAppointmentLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.appointmentNotiArray.count ];
        self.badgeMedicalRecordLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.medicalNotiArray.count ];
        self.badgeRequestLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.requestlNotiArray.count ];
    });


}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"homeScreenLoaded"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"homeScreenLoaded"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    //start animation
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];



    //stop animation
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadNotificationDataFromAPI];
            [self loadMessageDataFromAPI];
            [self.activityIndicator stopAnimating];
            [self.backgroundView removeFromSuperview];
        });
    });


}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"Home";
    self.messageNotiView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.patientRequestNotiView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.appointmentNotiView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.serviceNotiView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];

    self.avatar.layer.cornerRadius = self.avatar.frame.size.width / 2;
    self.avatar.clipsToBounds = YES;
    self.avatar.layer.borderWidth = 1.0f;
    self.avatar.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.messageNotiView.layer.cornerRadius = 5.0f;
    self.patientRequestNotiView.layer.cornerRadius = 5.0f;
    self.appointmentNotiView.layer.cornerRadius = 5.0f;
    self.serviceNotiView.layer.cornerRadius = 5.0f;

    //self.messageNotiView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    self.messageImage.image = [UIImage imageNamed:@"messageicon.png"];
    self.patientRequestImage.image = [UIImage imageNamed:@"requesticon.png"];
    self.appointmentImage.image = [UIImage imageNamed:@"newAppointmentIcon.png"];
    self.serviceImage.image = [UIImage imageNamed:@"serviceicon.png"];


    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.menuButton setTarget:self.revealViewController];
        [self.menuButton setAction:@selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }


    // Fetch the devices from persistent data store
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", [doctor valueForKey:@"firstName"], [doctor valueForKey:@"lastName"]];
    self.avatar.image = [UIImage imageWithData:[doctor valueForKey:@"photoURL"]];

    //set up tap gesture for each view
    [self setupAppointmentGestureRecognizer];
    [self setupMessageGestureRecognizer];
    [self setupMedicaRecordGestureRecognizer];
    [self setupPatientRequestGestureRecognizer];

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
#pragma mark handle tapgesture
-(void) setupAppointmentGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAppointmentTapGesture:)];
    //tapGesture.cancelsTouchesInView = NO;
    [self.appointmentNotiView addGestureRecognizer:tapGesture];
}

- (void)handleAppointmentTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self performSegueWithIdentifier:@"showAppointmentNoti" sender:self];
    //tell api that all appointment notification has been seen
    [self putSeenNotificationDataToAPIWithTopic:@[@0]];
}

-(void) setupMedicaRecordGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMedicalRecordTapGesture:)];
    //tapGesture.cancelsTouchesInView = NO;
    [self.serviceNotiView addGestureRecognizer:tapGesture];
}

- (void)handleMedicalRecordTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self performSegueWithIdentifier:@"medicalRecordNoti" sender:self];
    //tell api that all appointment notification has been seen
    [self putSeenNotificationDataToAPIWithTopic:@[@1,@2,@3,@4,@5,@6]];
}

-(void) setupPatientRequestGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePatientRequestTapGesture:)];
    //tapGesture.cancelsTouchesInView = NO;
    [self.patientRequestNotiView addGestureRecognizer:tapGesture];
}

- (void)handlePatientRequestTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self performSegueWithIdentifier:@"showNewRequestNotification" sender:self];
    //tell api that all appointment notification has been seen
    [self putSeenNotificationDataToAPIWithTopic:@[@7]];
}

-(void) setupMessageGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMessageTapGesture:)];
    //tapGesture.cancelsTouchesInView = NO;
    [self.messageNotiView addGestureRecognizer:tapGesture];
}

- (void)handleMessageTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self performSegueWithIdentifier:@"showChatNoti" sender:self];
    //tell api that all appointment notification has been seen

}





#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //show notification about appointment
    if ([[segue identifier] isEqualToString:@"showAppointmentNoti"])
    {
        ShowNotificationTableViewController *appointmentView = [segue destinationViewController];
        appointmentView.notifictionDataArray = (NSArray*)self.appointmentNotiArray;
        appointmentView.notificationType = 2;
    }
    //show notification about medical Record
    if ([[segue identifier] isEqualToString:@"medicalRecordNoti"])
    {
        ShowNotificationTableViewController *appointmentView = [segue destinationViewController];
        appointmentView.notifictionDataArray = (NSArray*)self.medicalNotiArray;
        appointmentView.notificationType = 3;
    }
    //show notification about new message
    if ([[segue identifier] isEqualToString:@"showChatNoti"])
    {
        ShowNotificationTableViewController *showChatView = [segue destinationViewController];
        showChatView.notificationType = 0;
        showChatView.notifictionDataArray = (NSArray*)self.messageNotiArray;
    }
    //show notification about patient request array
    if ([[segue identifier] isEqualToString:@"showNewRequestNotification"])
    {
        ManagePatientViewController *patientRequestView = [segue destinationViewController];
//        patientRequestView.notifictionDataArray = (NSArray*)self.requestlNotiArray;
        patientRequestView.isNotificationView = YES;
    }
}


@end
