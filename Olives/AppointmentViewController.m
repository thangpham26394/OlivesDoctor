//
//  AppointmentViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 6/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/appointment/filter"
#import "AppointmentViewController.h"
#import "SWRevealViewController.h"
#import "TimePickerViewController.h"
#import "AppointmentViewDetailViewController.h"
#import "AppointmentDetailTableViewCell.h"
#import <CoreData/CoreData.h>


@interface AppointmentViewController ()
@property (weak, nonatomic) IBOutlet UITableView *pendingListTableView;
@property (weak, nonatomic) IBOutlet UIView *calendarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarViewToTopDistance;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UITableView *listAppointMentInDayTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property(strong,nonatomic) NSMutableArray * markedDayList;
@property(strong,nonatomic) NSString * chosenDate;
@property (strong,nonatomic) NSDictionary *responseJSONData ;
@property (strong,nonatomic) NSDictionary *responseJSONDataForPendingList ;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addNewAppointmentBarButton;
@property(assign,nonatomic)BOOL addNewAppointmentBarButtonStatus;
@property(strong,nonatomic) NSArray * appointmentsInMonth;
@property(strong,nonatomic) NSArray * appointmentsForPending;
@property(strong,nonatomic) NSArray * appointmentsForExpired;
-(IBAction)addNewAppointment:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControlView;
- (IBAction)segmentController:(id)sender;
@property(assign,nonatomic) BOOL isShowingPendingFromPatient;
@property(assign,nonatomic) BOOL isShowingPendingFromDoctor;
@property(assign,nonatomic) BOOL isPendingFromPatient;
@property(strong,nonatomic) NSString *idOfSelectedAppointmentToviewDetail;
@property(strong,nonatomic) VRGCalendarView *calendar;
@property(assign,nonatomic) BOOL isActiveAppointment;

@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;



@end


@implementation AppointmentViewController


#pragma mark - Coredata function
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)loadAppointmentFromCoreDataWhenAPIFailFrom:(NSString *)fromDate To:(NSString*)toDate{
    NSMutableArray *appointmentArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Appointment"];
    NSMutableArray *appointmentObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *appointment;
    for (int index =0; index<appointmentObject.count; index++) {
        //get each patient in coredata
        appointment = [appointmentObject objectAtIndex:index];

        //only get from core data dates that inside range of fromDate to toDate
        if ([[appointment valueForKey:@"from"] doubleValue] >= [fromDate doubleValue]   &&   [[appointment valueForKey:@"to"] doubleValue] <= [toDate doubleValue] ) {
            NSDictionary *dater = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [appointment valueForKey:@"daterID" ],@"Id",
                                   [appointment valueForKey:@"daterFirstName" ],@"FirstName",
                                   [appointment valueForKey:@"daterLastName" ],@"LastName",
                                    nil];
            NSDictionary *maker = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [appointment valueForKey:@"makerID" ],@"Id",
                                   [appointment valueForKey:@"makerFirstName" ],@"FirstName",
                                   [appointment valueForKey:@"makerLastName" ],@"LastName",
                                   nil];

            NSDictionary *appointmentDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [appointment valueForKey:@"appointmentID" ],@"Id",
                                        [appointment valueForKey:@"dateCreated" ],@"Created",
                                        dater,@"Dater",
                                        maker,@"Maker",
                                        [appointment valueForKey:@"from" ],@"From",
                                        [appointment valueForKey:@"to" ],@"To",
                                        [appointment valueForKey:@"lastModified" ],@"LastModified",
                                        [appointment valueForKey:@"note" ],@"Note",
                                        [appointment valueForKey:@"status" ],@"Status",
                                        [appointment valueForKey:@"lastModifiedNote" ],@"LastModifiedNote",
                                        nil];
            [appointmentArrayForFailAPI addObject:appointmentDic];
        }
    }
    self.appointmentsInMonth = (NSArray*)appointmentArrayForFailAPI;
}



-(void)saveAppointmentInfoToCoreDataFrom:(NSString *)fromDate To:(NSString*)toDate{
    //get the appointments in current month which were returned from API
    self.appointmentsInMonth = [self.responseJSONData valueForKey:@"Appointments"];

    //delete all the current appointment in coredata for the selected month
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Appointment"];
    NSMutableArray *appointmentObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *appointment;
    if (appointmentObject.count >0) {

        for (int index=0; index < appointmentObject.count; index++) {
            appointment = [appointmentObject objectAtIndex:index];
            //check if current date is in range of from to date to delete
            if ([[appointment valueForKey:@"from"] doubleValue] >= [fromDate doubleValue]   &&   [[appointment valueForKey:@"to"] doubleValue] <= [toDate doubleValue] ) {
                [context deleteObject:appointment];//only delete the date that inside of selected month view in calendar
            }

        }
    }
    //insert each appointment that gotten from API before !
    for (int  runIndex =0; runIndex < self.appointmentsInMonth.count; runIndex++) {
        NSDictionary *appointmentDic = [self.appointmentsInMonth objectAtIndex:runIndex];

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


}


/*
 save to core data appointments with specific status <only pending and expire status>
 */
-(void)saveAppointmentInfoToCoreDataWith:(NSString*)pendingStatus{
    //get the appointments in current month which were returned from API
    NSArray *appointmentArray = [self.responseJSONDataForPendingList valueForKey:@"Appointments"];
    if ([pendingStatus isEqual:@"1"]) {
        self.appointmentsForPending = appointmentArray;
    }else{
        self.appointmentsForExpired = appointmentArray;
    }


    //delete all the current appointment in coredata for the selected month
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Appointment"];
    NSMutableArray *appointmentObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *appointment;
    if (appointmentObject.count >0) {

        for (int index=0; index < appointmentObject.count; index++) {
            appointment = [appointmentObject objectAtIndex:index];
            //check if current date status is equal to pending status
            if ([[appointment valueForKey:@"status"] isEqual:pendingStatus]) {
                [context deleteObject:appointment];//only delete the date that have status we want
            }

        }
    }
    //insert each appointment that gotten from API before !
    for (int  runIndex =0; runIndex < appointmentArray.count; runIndex++) {
        NSDictionary *appointmentDic = [appointmentArray objectAtIndex:runIndex];

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

}
/*
 load from coredata when API fail to display data in pending table
 */
-(void)loadAppointmentFromCoreDataWhenAPIFailWith:(NSString*)pendingStatus{
    NSMutableArray *appointmentArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Appointment"];
    NSMutableArray *appointmentObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *appointment;
    for (int index =0; index<appointmentObject.count; index++) {
        //get each patient in coredata
        appointment = [appointmentObject objectAtIndex:index];

        //only get from core data dates that have status equal to pending status
        if ([[appointment valueForKey:@"status"] isEqual:pendingStatus]) {
            NSDictionary *dater = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [appointment valueForKey:@"daterID" ],@"Id",
                                   [appointment valueForKey:@"daterFirstName" ],@"FirstName",
                                   [appointment valueForKey:@"daterLastName" ],@"LastName",
                                   nil];
            NSDictionary *maker = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [appointment valueForKey:@"makerID" ],@"Id",
                                   [appointment valueForKey:@"makerFirstName" ],@"FirstName",
                                   [appointment valueForKey:@"makerLastName" ],@"LastName",
                                   nil];

            NSDictionary *appointmentDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [appointment valueForKey:@"appointmentID" ],@"Id",
                                            [appointment valueForKey:@"dateCreated" ],@"Created",
                                            dater,@"Dater",
                                            maker,@"Maker",
                                            [appointment valueForKey:@"from" ],@"From",
                                            [appointment valueForKey:@"to" ],@"To",
                                            [appointment valueForKey:@"lastModified" ],@"LastModified",
                                            [appointment valueForKey:@"note" ],@"Note",
                                            [appointment valueForKey:@"status" ],@"Status",
                                            [appointment valueForKey:@"lastModifiedNote" ],@"LastModifiedNote",
                                            nil];
            [appointmentArrayForFailAPI addObject:appointmentDic];
        }
    }
    if ([pendingStatus isEqual:@"1"]) {
        self.appointmentsForPending = (NSArray*)appointmentArrayForFailAPI;
    }else{
        self.appointmentsForExpired = (NSArray*)appointmentArrayForFailAPI;
    }
}






#pragma mark - Connect to API function

/*
 function call to API just for pending List <only pending and expire status>
 */
-(NSDictionary*)loadAppointmentDataFromAPIWithStatus:(NSInteger)status{
    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Status" :  [NSString stringWithFormat:@"%ld",(long)status]
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];
    // config session
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    //NSURLSession *defaultSession = [NSURLSession sharedSession];
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
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:email forHTTPHeaderField:@"Email"];
    [urlRequest setValue:password forHTTPHeaderField:@"Password"];
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
                                              self.responseJSONDataForPendingList = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];

                                              if (self.responseJSONDataForPendingList != nil) {
                                                  [self saveAppointmentInfoToCoreDataWith:[NSString stringWithFormat:@"%ld",(long)status]];
                                              }else{
                                                  [self loadAppointmentFromCoreDataWhenAPIFailWith:[NSString stringWithFormat:@"%ld",(long)status]];
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              [self loadAppointmentFromCoreDataWhenAPIFailWith:[NSString stringWithFormat:@"%ld",(long)status]];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);


    return self.responseJSONDataForPendingList;
}


-(NSDictionary*)loadAppointmentDataFromAPIFrom:(NSString *)minDate and:(NSString *) maxDate{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    //create JSON data to post to API
    NSDictionary *account = @{
                              @"MinFrom" :  minDate,
                              @"MaxTo" : maxDate
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];

    // config session
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    //NSURLSession *defaultSession = [NSURLSession sharedSession];
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
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:email forHTTPHeaderField:@"Email"];
    [urlRequest setValue:password forHTTPHeaderField:@"Password"];
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
                                                  [self saveAppointmentInfoToCoreDataFrom:minDate To:maxDate];
                                              }else{
                                                  [self loadAppointmentFromCoreDataWhenAPIFailFrom:minDate To:maxDate];
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              [self loadAppointmentFromCoreDataWhenAPIFailFrom:minDate To:maxDate];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return self.responseJSONData;
}

#pragma mark - View delegate

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.view reloadInputViews];
    self.appointmentsInMonth = [[NSArray alloc]init];
    self.appointmentsForExpired = [[NSArray alloc]init];
    self.appointmentsForPending = [[NSArray alloc]init];
    self.pendingListTableView.userInteractionEnabled = YES;
    self.listAppointMentInDayTableView.userInteractionEnabled = YES;


    //start animation
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];



    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            //call function connect to API to get data for pending Table
            [self loadAppointmentDataFromAPIWithStatus:1]; //pending
            [self loadAppointmentDataFromAPIWithStatus:4];//expired

            [self.pendingListTableView reloadData];
            int month = [[NSUserDefaults standardUserDefaults] doubleForKey:@"currentMonth"];
            double targetHeight = [[NSUserDefaults standardUserDefaults] doubleForKey:@"targetHeight"];
            double currentSelectedDate = [[NSUserDefaults standardUserDefaults] doubleForKey:@"currentSelectedDate"];
            NSDate *selectedDate = [NSDate dateWithTimeIntervalSince1970:currentSelectedDate];
            BOOL isfirstLoad = [[NSUserDefaults standardUserDefaults] boolForKey:@"firstLoadAppointment"];
            if (!isfirstLoad) {
                [self calendarView:self.calendar switchedToMonth:month targetHeight:targetHeight animated:YES];
                [self calendarView:self.calendar dateSelected:selectedDate];
            }


            if (self.segmentControlView.selectedSegmentIndex ==1) {
                [self.addNewAppointmentBarButton setEnabled:NO];
                [self.pendingListTableView setHidden:NO];
                [self.pendingListTableView reloadData];
                
            }
            [self.activityIndicator stopAnimating];
            [self.backgroundView removeFromSuperview];
        });
    });







}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"firstLoadAppointment"];

    [[NSUserDefaults standardUserDefaults] synchronize];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    //check if view is first loading
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLoadAppointment"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.segmentControlView.tintColor = [UIColor colorWithRed:0/255.0 green:150/255.0 blue:136/255.0 alpha:1.0];
    if (self.isShowNotification) {
        self.segmentControlView.selectedSegmentIndex =1;
    }else{
        [self.pendingListTableView setHidden:YES];
    }

    self.isShowingPendingFromDoctor = NO;
    self.isShowingPendingFromPatient = NO;

    self.markedDayList = [[NSMutableArray alloc] init];

    //setup listAppointMentInDayTableView
    [self.listAppointMentInDayTableView.layer setCornerRadius:5.0f];
    [self.listAppointMentInDayTableView setShowsVerticalScrollIndicator:NO];
    
    [self.listAppointMentInDayTableView setSeparatorColor:[UIColor colorWithRed:0/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]];
    [self.listAppointMentInDayTableView setHidden:YES];
    self.listAppointMentInDayTableView.layer.borderColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0].CGColor;
    self.listAppointMentInDayTableView.layer.borderWidth = 1.0f;

    SWRevealViewController *revealViewController = self.revealViewController;

    if (revealViewController) {
        [self.menuButton setTarget:self.revealViewController];
        [self.menuButton setAction:@selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    //check device using is 4inch screen or not to et distance to top from calendar view
    if ( [[UIScreen mainScreen] bounds].size.height == 568) {
        self.calendarViewToTopDistance.constant = 30;
    }else{
        self.calendarViewToTopDistance.constant = 45;
    }
    self.calendarView.layer.borderColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0].CGColor;
    self.calendarView.layer.borderWidth = 1.0f;
    [self.calendarView.layer setCornerRadius:5.0f];
    self.calendar = [[VRGCalendarView alloc] init];

    self.calendar.delegate = self;
    //set selected date is today
    [self calendarView:self.calendar dateSelected:[NSDate date]];
    //set up layout for calendar subview
    self.calendar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.calendarView setBackgroundColor:[UIColor clearColor]];
    [self.calendarView addSubview:self.calendar];

    [self.calendarView  layoutIfNeeded];

    //set up for indicator view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(screenWidth/2-20,screenHeight/2-20 , 40, 40)];
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

-(IBAction)addNewAppointment:(id)sender{
    [self performSegueWithIdentifier: @"addNewAppointment" sender: self];
}

#pragma mark - Extract data received from API

-(NSMutableArray*)markedDateInCurrentMonth{
    NSMutableArray *markedDatesArray = [[NSMutableArray alloc] init];


    for (int i=0; i<self.appointmentsInMonth.count; i++) {
        //don't get the pending appointment
        if ( ![[NSString stringWithFormat:@"%@",[self.appointmentsInMonth[i] objectForKey:@"Status"] ] isEqual:@"1"] && ![[NSString stringWithFormat:@"%@",[self.appointmentsInMonth[i] objectForKey:@"Status"] ] isEqual:@"4"]  ) {

            //get a specific appointment
            NSDictionary *currentAppointment = [self.appointmentsInMonth objectAtIndex:i];

            //get time interval for that appointment
            NSString *startTime = [currentAppointment valueForKey:@"From"];

            NSDate *startAppointMentTime = [NSDate dateWithTimeIntervalSince1970:[startTime doubleValue]/1000];

            //add appointment date to marked date array in calendarView
            NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
            [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
            [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];

            //convert date to system date time
            NSDate *sysDateTime = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:startAppointMentTime]];
            
            [markedDatesArray addObject:sysDateTime];

        }



    }
    return markedDatesArray;
}


#pragma mark - Handle Calendar date time

-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated {

    //disable addnew appointment button if thereis no day selected
    [self.addNewAppointmentBarButton setEnabled:NO];
    self.addNewAppointmentBarButtonStatus = NO;
    //hide listAppointMentInDayTableView if need
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionFade;
    animation.duration = 0.25;
    [self.listAppointMentInDayTableView.layer addAnimation:animation forKey:nil];
    [self.listAppointMentInDayTableView setHidden:YES];

    //set up height for listAppointMentInDayTableView to fit the calendar
    self.contentViewHeight.constant = targetHeight;
    [UIView animateWithDuration:0.35
                     animations:^{
                         [self.view layoutIfNeeded]; // Called on parent view
                     }];


    // dateformater to convert to UTC time zone
    NSDateFormatter *dateFormaterToUTC = [[NSDateFormatter alloc] init];
    dateFormaterToUTC.timeStyle = NSDateFormatterNoStyle;
    dateFormaterToUTC.dateFormat = @"MM/dd/yyyy HH:mm:ss:SSS";
    [dateFormaterToUTC setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];



    //get start datetime and finish datetime
    int firstWeekDay = [self firstWeekDayInMonth:calendarView.currentMonth];

    //get the unix format mindate from current calendar's month
    NSString *startDate = [self calendarStartDateWithFirstWeekDay:firstWeekDay andCurrentMonth:calendarView.currentMonth];
    NSDate *minDate = [dateFormaterToUTC dateFromString:startDate];
    NSTimeInterval unixMinDate = [minDate timeIntervalSince1970];


    //get the unix maxdate from current calendar's month
    NSString *endDate = [self calendarEndDateWithFirstWeekDay:firstWeekDay andCurrentMonth:calendarView.currentMonth];
    NSDate *maxDate = [dateFormaterToUTC dateFromString:endDate];
    //set time to the end of the day to max date


    NSTimeInterval unixMaxDate = [maxDate timeIntervalSince1970];

    //start animation
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];

    [self loadAppointmentDataFromAPIFrom:[NSString stringWithFormat:@"%f",unixMinDate*1000] and:[NSString stringWithFormat:@"%f",unixMaxDate*1000]];

    //stop animation
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            [self.backgroundView removeFromSuperview];
        });
    });




    [[NSUserDefaults standardUserDefaults] setInteger:month forKey:@"currentMonth"];
    [[NSUserDefaults standardUserDefaults] setDouble:targetHeight forKey:@"targetHeight"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    self.markedDayList = [self markedDateInCurrentMonth];
    [calendarView markDates:self.markedDayList];

//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSDate *date = [NSDate date];
//    if (month==[calendar component:NSCalendarUnitMonth fromDate:date]) {
//
//        self.markedDayList = [self markedDateInCurrentMonth];
//        [calendarView markDates:self.markedDayList];
//    }


    //check if today is marked date
    BOOL isMarkedDate = NO;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];

    NSString *today = [dateFormatter stringFromDate:[NSDate date]];
    self.chosenDate = today;
    //set enable for add new appointment bar button if the current month is showing in first time
    if ([[dateFormatter stringFromDate:calendarView.currentMonth] isEqual:today]) {
        [self.addNewAppointmentBarButton setEnabled:YES];
        self.addNewAppointmentBarButtonStatus = YES;
    }
    for (int runIndex = 0; runIndex <self.markedDayList.count; runIndex ++) {
        NSString *currentDate = [dateFormatter stringFromDate:[self.markedDayList objectAtIndex:runIndex]];
        if ([today isEqual:currentDate]) {
            isMarkedDate = YES;
        }
    }

    //show list appoint for today
    if (isMarkedDate && [[dateFormatter stringFromDate:calendarView.currentMonth] isEqual:today]) {
        NSTimeInterval selectedDateTimeInterval = [[NSDate date] timeIntervalSince1970];
        [[NSUserDefaults standardUserDefaults] setDouble:selectedDateTimeInterval forKey:@"currentSelectedDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        animation.duration = 0.35;
        [self.listAppointMentInDayTableView.layer addAnimation:animation forKey:nil];
        [self.listAppointMentInDayTableView setHidden:NO];
        [self.listAppointMentInDayTableView reloadData];
    }
}


-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date {
    NSTimeInterval selectedDateTimeInterval = [date timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setDouble:selectedDateTimeInterval forKey:@"currentSelectedDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.addNewAppointmentBarButton setEnabled:YES];
    self.addNewAppointmentBarButtonStatus = YES;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];

    NSLog(@"Selected date = %@",[dateFormatter stringFromDate:date]);
    self.chosenDate =[dateFormatter stringFromDate:date];

    //check if chosen date is marked date or not
    BOOL isMarkedDate = NO;
    for (int runIndex = 0; runIndex <self.markedDayList.count; runIndex ++) {
        NSString *currentMarkedDate = [dateFormatter stringFromDate:[self.markedDayList objectAtIndex:runIndex]];
        if ([self.chosenDate isEqual:currentMarkedDate]) {
            isMarkedDate = YES;
        }
    }

    //if the chosen date is also a marked date then show the list appointment in chosenday

    //animation to show or hide listAppointMentInDayTableView
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionFade;
    if (isMarkedDate) {
        animation.duration = 0.35;
        [self.listAppointMentInDayTableView.layer addAnimation:animation forKey:nil];
        [self.listAppointMentInDayTableView setHidden:NO];
        [self.listAppointMentInDayTableView reloadData];
    }else{
        animation.duration = 0.25;
        [self.listAppointMentInDayTableView.layer addAnimation:animation forKey:nil];
        [self.listAppointMentInDayTableView setHidden:YES];
    }

    //    [self performSegueWithIdentifier:@"showAppointment" sender:self];
}


-(NSString *)calendarStartDateWithFirstWeekDay :(int)firstWeekDay andCurrentMonth:(NSDate*)currentMonth{
    if (firstWeekDay>1) {
        NSDate *previousMonth = [self offsetMonth:-1 withMonth:currentMonth];
        int lastMonthNumDays = [self numDaysInMonth:previousMonth];
        int std = lastMonthNumDays - firstWeekDay +2;
        return  [NSString stringWithFormat:@"%d/%d/%d 00:00:00:000",[self month:previousMonth],std,[self year:previousMonth]];
    }else{
        return [NSString stringWithFormat:@"%d/%d/%d 00:00:00:000",[self month:currentMonth],01,[self year:currentMonth]];
    }

}

-(NSString *)calendarEndDateWithFirstWeekDay :(int)firstWeekDay andCurrentMonth:(NSDate*)currentMonth{
    int currentMonthAndLastMonthTotalDays = [self numDaysInMonth:currentMonth] + firstWeekDay -1;
    int lastDay = (7 - currentMonthAndLastMonthTotalDays%7)%7;

    if (lastDay==0) {
        return [NSString stringWithFormat:@"%d/%d/%d 23:59:59:999",[self month:currentMonth],[self numDaysInMonth:currentMonth],[self year:currentMonth]];
    }else{
        NSDate *nextMonth = [self offsetMonth:+1 withMonth:currentMonth];
        return [NSString stringWithFormat:@"%d/%d/%d 23:59:59:999",[self month:nextMonth],lastDay,[self year:nextMonth]];
    }

}

-(int)year:(NSDate*)date {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitYear fromDate:date];
    return (int)[components year];
}


-(int)month:(NSDate*)date  {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitMonth fromDate:date];
    return (int)[components month];
}

-(int)day:(NSDate*)date  {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitDay fromDate:date];
    return (int)[components day];
}
-(int)numDaysInMonth:(NSDate *)month{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSRange rng = [cal rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:month];
    NSUInteger numberOfDaysInMonth = rng.length;
    return (int)numberOfDaysInMonth;
}

-(int)firstWeekDayInMonth:(NSDate*) currentDate {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setFirstWeekday:2]; //monday is first day
    //[gregorian setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"]];

    //Set date to first of month
    NSDateComponents *comps = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay fromDate:currentDate];
    [comps setDay:1];
    NSDate *newDate = [gregorian dateFromComponents:comps];

    return (int)[gregorian ordinalityOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfMonth forDate:newDate];
}

-(NSDate *)offsetMonth:(int)numMonths withMonth:(NSDate*)date{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [NSDateComponents new];
    comps.month = numMonths;
    NSDate *newDate = [calendar dateByAddingComponents:comps toDate:date options:0];

    return newDate;
}

#pragma mark - Table view data source

-(NSMutableArray *)appointmentsForSelectedDate:(NSDate *)selectedDate{

    //declare initital array
    NSMutableArray *appointmentsForSelectedDateArray = [[NSMutableArray alloc]init];
    //go throught every appointment in current month
    for (int index = 0; index < self.appointmentsInMonth.count; index ++) {
        if (![[NSString stringWithFormat:@"%@",[self.appointmentsInMonth[index] objectForKey:@"Status"] ] isEqual:@"1"] && ![[NSString stringWithFormat:@"%@",[self.appointmentsInMonth[index] objectForKey:@"Status"] ] isEqual:@"4"] ) {
            //get a specific appointment
            NSDictionary *currentAppointment = [self.appointmentsInMonth objectAtIndex:index];

            //get time interval for that appointment from dictionary
            NSString *startTime = [currentAppointment valueForKey:@"From"];
            NSString *endTime = [currentAppointment valueForKey:@"To"];
            //get other informations about current appointment
            NSString *daterId = [NSString stringWithFormat:@"%@",[[currentAppointment valueForKey:@"Dater"] valueForKey:@"Id"]];
            NSString *appointmentID = [currentAppointment valueForKey:@"Id"];
            NSString *status = [currentAppointment valueForKey:@"Status"];
            //convert time interval to NSDate type
            NSDate *startAppointMentTime = [NSDate dateWithTimeIntervalSince1970:[startTime doubleValue]/1000];
            NSDate *endAppointMentTime = [NSDate dateWithTimeIntervalSince1970:[endTime doubleValue]/1000];

            //convert to local time zone to check if the date is selected date !?
            NSDateFormatter * dateFormatterToLocalToCheck = [[NSDateFormatter alloc] init];
            [dateFormatterToLocalToCheck setTimeZone:[NSTimeZone systemTimeZone]];
            [dateFormatterToLocalToCheck setDateFormat:@"MM/dd/yyyy"];

            //convert date to system date time
            NSDate *sysDateTimeToCheck = [dateFormatterToLocalToCheck dateFromString:[dateFormatterToLocalToCheck stringFromDate:startAppointMentTime]];

            //check if the current date is selected date
            if ([sysDateTimeToCheck isEqual:selectedDate]) {
                NSString *patientID;
                NSString *patientFirstName;
                NSString *patientLastName;
                //check if current doctor using app is maker or dater of appointment
                //get the current doctor data
                NSManagedObjectContext *context = [self managedObjectContext];
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
                NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

                NSManagedObject *doctor = [doctorObject objectAtIndex:0];
                if ([daterId  isEqual: [doctor valueForKey:@"doctorID"]]) {
                    // doctor is dater then maker is patient
                    patientID = [[currentAppointment valueForKey:@"Maker"] valueForKey:@"Id"];
                    patientFirstName = [[currentAppointment valueForKey:@"Maker"] valueForKey:@"FirstName"];
                    patientLastName = [[currentAppointment valueForKey:@"Maker"] valueForKey:@"LastName"];

                }else{
                    //doctor is maker then dater is patient
                    patientID = [[currentAppointment valueForKey:@"Dater"] valueForKey:@"Id"];
                    patientFirstName = [[currentAppointment valueForKey:@"Dater"] valueForKey:@"FirstName"];
                    patientLastName = [[currentAppointment valueForKey:@"Dater"] valueForKey:@"LastName"];


                }



                //configure dateformater in time format
                NSDateFormatter * timeFormatterToLocal = [[NSDateFormatter alloc] init];
                [timeFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
                [timeFormatterToLocal setDateFormat:@"HH:mm"];

                //get string time from currentdate
                NSString *startTimeForCurrentAppointment = [timeFormatterToLocal stringFromDate:startAppointMentTime];
                NSString *endTimeForCurrentAppointment = [timeFormatterToLocal stringFromDate:endAppointMentTime];

                //put both start and end time to 1 dictionary var
                NSDictionary *startAndEndTimeForSelectedDate = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                appointmentID,@"appointmentID",
                                                                status,@"status",
                                                                patientID,@"patientID",
                                                                patientFirstName,@"patientFirstName",
                                                                patientLastName,@"patientLastName",
                                                                startTimeForCurrentAppointment, @"startTime",
                                                                endTimeForCurrentAppointment, @"endTime"
                                                                , nil];
                //append initial array with information about start and end time
                [appointmentsForSelectedDateArray addObject:startAndEndTimeForSelectedDate];
            }

        }

    }




    return appointmentsForSelectedDateArray;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.segmentControlView.selectedSegmentIndex ==0) {
        return 1;
    }else{
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.segmentControlView.selectedSegmentIndex ==0) {
        if (self.chosenDate ==nil || [self.chosenDate isEqualToString:@""]) {
            return 0;

        }else{
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            NSDate *dateSelected = [dateFormatter dateFromString:self.chosenDate];
            NSMutableArray*startAndEndTime =  [self appointmentsForSelectedDate:dateSelected];
            return startAndEndTime.count;
        }
    }else{
        // number of pending appointment
        if (section ==0) {
            return [self pendingAppointmentFromPatient].count;
        }else{
            return [self pendingAppointmentFromDoctor].count;
        }

    }
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    NSString *sectionName;
    if (self.segmentControlView.selectedSegmentIndex ==1) {
        switch (section)
        {
            case 0:
                if ([self pendingAppointmentFromPatient].count>0) {
                    sectionName = @"Pending from Patient";
                }
                break;
            case 1:
                if ([self pendingAppointmentFromDoctor].count>0) {
                    sectionName = @"Waiting patient approve";
                }


                break;
            default:
                sectionName = @"";
                break;
        }
    }
    return sectionName;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (self.segmentControlView.selectedSegmentIndex ==1) {
        if (section ==0) {
            if ([self pendingAppointmentFromPatient].count>0) {
                return 40;
            }
            return 0;
        }else{
            if ([self pendingAppointmentFromDoctor].count>0) {
                return 40;
            }
            return 0;
        }

    }else{
        return 0;
    }
}

 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     if (self.segmentControlView.selectedSegmentIndex ==0) {
         //when select first segment
         AppointmentDetailTableViewCell *cell = [self.listAppointMentInDayTableView dequeueReusableCellWithIdentifier:@"appointmentDetailCell" forIndexPath:indexPath];

         // Configure the cell...
         NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
         [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
         [dateFormatter setDateFormat:@"MM/dd/yyyy"];
         NSDate *dateSelected = [dateFormatter dateFromString:self.chosenDate];
         NSMutableArray*startAndEndTime =  [self appointmentsForSelectedDate:dateSelected];
         if (startAndEndTime.count ==0) {
             return cell;
         }
         if (self.chosenDate ==nil || [self.chosenDate isEqualToString:@""] ){
             cell.nameLabel.text = @"";
             cell.timeLabel.text = @"";
         }else{
             cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@",[[startAndEndTime objectAtIndex:indexPath.row] objectForKey:@"patientFirstName"],[[startAndEndTime objectAtIndex:indexPath.row] objectForKey:@"patientLastName"]];
             cell.timeLabel.text = [NSString stringWithFormat:@"%@ to %@",[[startAndEndTime objectAtIndex:indexPath.row] objectForKey:@"startTime"],[[startAndEndTime objectAtIndex:indexPath.row] objectForKey:@"endTime"]];
         }
         //if appoint in cell is avtive then change background color to white color, else change to gray color
         if ([[NSString stringWithFormat:@"%@",[[startAndEndTime objectAtIndex:indexPath.row]  objectForKey:@"status"]] isEqual:@"2"]) {
             //cell for active appointment
             cell.timeLabel.textColor = [UIColor lightGrayColor];
             cell.backgroundColor = [UIColor whiteColor];
         }else{
             //cell for not active appointment
             cell.backgroundColor = [UIColor lightGrayColor];
             if ([[NSString stringWithFormat:@"%@",[[startAndEndTime objectAtIndex:indexPath.row]  objectForKey:@"status"]] isEqual:@"0"]) {
                 cell.timeLabel.text = @"Canceled";
                 cell.timeLabel.textColor = [UIColor redColor];
             }
             if ([[NSString stringWithFormat:@"%@",[[startAndEndTime objectAtIndex:indexPath.row]  objectForKey:@"status"]] isEqual:@"3"]) {
                 cell.timeLabel.text = @"Done";
                 cell.timeLabel.textColor = [UIColor redColor];
             }
         }

         cell.preservesSuperviewLayoutMargins = NO;
         cell.separatorInset = UIEdgeInsetsZero;
         cell.layoutMargins = UIEdgeInsetsZero;

         return cell;
     }else{
         //when select second segment control
         NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
         [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
         [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];
         AppointmentDetailTableViewCell *cell = [self.pendingListTableView dequeueReusableCellWithIdentifier:@"pendingAppointmentCell" forIndexPath:indexPath];
         NSDictionary *appointmentDic = [[NSDictionary alloc]init];
         if (indexPath.section ==0) {
             //pending from patient
             appointmentDic = [self pendingAppointmentFromPatient][indexPath.row];
             NSString *firstName = [[appointmentDic objectForKey:@"Maker"]objectForKey:@"FirstName"];
             NSString *lastName = [[appointmentDic objectForKey:@"Maker"]objectForKey:@"LastName"];
             cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@",firstName,lastName];


         }else{
             //pending from doctor
             appointmentDic = [self pendingAppointmentFromDoctor][indexPath.row];
             NSString *firstName = [[appointmentDic objectForKey:@"Dater"]objectForKey:@"FirstName"];
             NSString *lastName = [[appointmentDic objectForKey:@"Dater"]objectForKey:@"LastName"];
             cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
         }

         NSDate *from = [NSDate dateWithTimeIntervalSince1970:[[appointmentDic objectForKey:@"From"] doubleValue]/1000];
         NSDate *fromDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:from]];
         cell.timeLabel.text = [NSString stringWithFormat:@"%@",[dateFormatterToLocal stringFromDate:fromDateLocal]];
         if ([[NSString stringWithFormat:@"%@",[appointmentDic objectForKey:@"Status"]] isEqual:@"4"]) {
             cell.timeLabel.text = @"Expired";
             cell.timeLabel.textColor = [UIColor redColor];
             cell.backgroundColor = [UIColor lightGrayColor];
         }else{
             cell.timeLabel.textColor = [UIColor lightGrayColor];
             cell.backgroundColor = [UIColor whiteColor];
         }
         return cell;
     }

 }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    if (self.segmentControlView.selectedSegmentIndex ==0) {
        NSDate *dateSelected = [dateFormatter dateFromString:self.chosenDate];
        NSMutableArray*appointmentsInSelectedDate =  [self appointmentsForSelectedDate:dateSelected];
        self.idOfSelectedAppointmentToviewDetail = [NSString stringWithFormat:@"%@",[appointmentsInSelectedDate[indexPath.row] objectForKey:@"appointmentID"]];

        if ([[NSString stringWithFormat:@"%@",[[appointmentsInSelectedDate objectAtIndex:indexPath.row]  objectForKey:@"status"]] isEqual:@"2"]) {
            self.isActiveAppointment = YES;
        }else{
            self.isActiveAppointment = NO;
        }
        [self performSegueWithIdentifier:@"showDetalAppointment" sender:self];
        [self.listAppointMentInDayTableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.listAppointMentInDayTableView setUserInteractionEnabled:NO];



    }else{
        NSDictionary *appointmentDic = [[NSDictionary alloc]init];
        if (indexPath.section ==0) {
            //pending from patient
            appointmentDic = [self pendingAppointmentFromPatient][indexPath.row];
            self.isPendingFromPatient = YES;
            if ([[NSString stringWithFormat:@"%@",[appointmentDic objectForKey:@"Status"]] isEqual:@"1"]) {
                self.isActiveAppointment = YES;
            }else{
                self.isActiveAppointment = NO;
            }
        }else{
            //pending from doctor
            appointmentDic = [self pendingAppointmentFromDoctor][indexPath.row];
            self.isPendingFromPatient = NO;
            if ([[NSString stringWithFormat:@"%@",[appointmentDic objectForKey:@"Status"]] isEqual:@"1"]) {
                self.isActiveAppointment = YES;
            }else{
                self.isActiveAppointment = NO;
            }
        }

        self.idOfSelectedAppointmentToviewDetail = [NSString stringWithFormat:@"%@",[appointmentDic objectForKey:@"Id"]];
        NSTimeInterval fromDateTimeInterval = [[appointmentDic objectForKey:@"From"] doubleValue]/1000;
        NSDate *fromDate = [NSDate dateWithTimeIntervalSince1970:fromDateTimeInterval];
        self.chosenDate = [dateFormatter stringFromDate:fromDate];
        [self performSegueWithIdentifier:@"showDetalAppointment" sender:self];
        [self.pendingListTableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.pendingListTableView setUserInteractionEnabled:NO];
    }

}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"addNewAppointment"])
    {
        TimePickerViewController *timePickerController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        timePickerController.chosenDate = self.chosenDate;
    }
    if ([[segue identifier] isEqualToString:@"showDetalAppointment"])
    {
        TimePickerViewController *timePickerController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        timePickerController.appointmentID = self.idOfSelectedAppointmentToviewDetail;
        timePickerController.chosenDate = self.chosenDate;
        if (self.segmentControlView.selectedSegmentIndex ==0) {
            timePickerController.segmentUsing = @"Calendar";
            if (self.isActiveAppointment) {
                timePickerController.isActiveAppointment = YES;
            }else{
                timePickerController.isActiveAppointment = NO;
            }
        }else{
            if (self.isPendingFromPatient) {
                timePickerController.segmentUsing = @"PendingFromPatient";
            }else{
                timePickerController.segmentUsing = @"PendingFromDoctor";
            }
            if (self.isActiveAppointment) {
                timePickerController.isActiveAppointment = YES;
            }else{
                timePickerController.isActiveAppointment = NO;
            }

        }

    }
}


- (IBAction)segmentController:(id)sender {
    switch (self.segmentControlView.selectedSegmentIndex)
    {
        case 0:
            [self.pendingListTableView setHidden:YES];
            if (self.addNewAppointmentBarButtonStatus) {
                [self.addNewAppointmentBarButton setEnabled:YES];
            }
            //[self.pendingListTableView reloadData];
            [self.listAppointMentInDayTableView reloadData];
            break;
        case 1:
            [self.addNewAppointmentBarButton setEnabled:NO];
            [self.pendingListTableView setHidden:NO];
            [self.pendingListTableView reloadData];
            //[self.listAppointMentInDayTableView reloadData];
            break;
        default:
            break;
    }
}


#pragma mark - Table view data source
-(NSArray*)pendingAppointmentFromPatient{
    NSMutableArray *pendingArray =  [[NSMutableArray alloc] init];
    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];

    //add two array <pending and expire> into 1 array;
    NSMutableArray *totalPending =  [[NSMutableArray alloc] init];
    for (int index =0; index < self.appointmentsForPending.count; index ++) {
        [totalPending addObject:self.appointmentsForPending[index]];
    }
    for (int index =0; index < self.appointmentsForExpired.count; index ++) {
        [totalPending addObject:self.appointmentsForExpired[index]];
    }

    for (int index =0; index < totalPending.count; index ++) {
        //get the current appointment
        NSDictionary *appointment = totalPending[index];
        //check if dater id is equal to doctor id or not
        if ([[NSString stringWithFormat:@"%@",[[appointment objectForKey:@"Dater"] objectForKey:@"Id"]] isEqual:[doctor valueForKey:@"doctorID"]]) {
            //check to get appointment with status is pending or expire only
            if ([ [NSString stringWithFormat:@"%@",[appointment objectForKey:@"Status"] ] isEqual:@"1"] || [[NSString stringWithFormat:@"%@",[appointment objectForKey:@"Status"] ] isEqual:@"4"] ) {
                [pendingArray addObject:appointment];
            }

        }
    }

    return (NSArray*)pendingArray;
}


-(NSArray*)pendingAppointmentFromDoctor{
    NSMutableArray *pendingArray =  [[NSMutableArray alloc] init];
    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];

    //add two array <pending and expire> into 1 array;
    NSMutableArray *totalPending =  [[NSMutableArray alloc] init];
    for (int index =0; index < self.appointmentsForPending.count; index ++) {
        [totalPending addObject:self.appointmentsForPending[index]];
    }
    for (int index =0; index < self.appointmentsForExpired.count; index ++) {
        [totalPending addObject:self.appointmentsForExpired[index]];
    }

    for (int index =0; index < totalPending.count; index ++) {
        //get the current appointment
        NSDictionary *appointment = totalPending[index];
        //check if maker id is equal to doctor id or not
        if ([[NSString stringWithFormat:@"%@",[[appointment objectForKey:@"Maker"] objectForKey:@"Id"]] isEqual:[doctor valueForKey:@"doctorID"]]) {
            //check to get appointment with status is pending or expire only
            if ([ [NSString stringWithFormat:@"%@",[appointment objectForKey:@"Status"] ] isEqual:@"1"] || [[NSString stringWithFormat:@"%@",[appointment objectForKey:@"Status"] ] isEqual:@"4"] ) {
                [pendingArray addObject:appointment];
            }
        }
    }

    return (NSArray*)pendingArray;
}

@end
