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
#import "PatientsTableViewController.h"
#import "AppointmentViewDetailViewController.h"
#import <CoreData/CoreData.h>


@interface AppointmentViewController ()
@property (weak, nonatomic) IBOutlet UIView *calendarView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarViewToTopDistance;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UITableView *listAppointMentInDayTableView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property(strong,nonatomic) NSMutableArray * markedDayList;
@property(strong,nonatomic) NSString * chosenDate;
@property (strong,nonatomic) NSDictionary *responseJSONData ;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addNewAppointmentBarButton;

-(IBAction)addNewAppointment:(id)sender;
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

-(void)saveAppointmentInfoToCoreData:(NSDictionary*) jsonData{
    NSArray * appointments = [jsonData valueForKey:@"Appointments"];
    for (int  runIndex =0; runIndex < appointments.count; runIndex++) {
        NSDictionary *appointmentDic = [appointments objectAtIndex:runIndex];

        NSString * appointmentID = [appointmentDic valueForKey:@"Id"];
        NSString * dateCreated = [appointmentDic valueForKey:@"Created"];

        NSString * daterId = [[appointmentDic valueForKey:@"Dater"]  valueForKey:@"Id"];
        NSString * daterFirstName = [[appointmentDic valueForKey:@"Dater"] valueForKey:@"FirstName"];
        NSString * daterLastName = [[appointmentDic valueForKey:@"Dater"] valueForKey:@"LastName"];

        NSString * makerId = [[appointmentDic valueForKey:@"Maker"]  valueForKey:@"Id"];
        NSString * makerFirstName = [[appointmentDic valueForKey:@"Maker"] valueForKey:@"FirstName"];
        NSString * makerrLastName = [[appointmentDic valueForKey:@"Maker"] valueForKey:@"LastName"];

        NSString * from = [appointmentDic valueForKey:@"From"];
        NSString * to = [appointmentDic valueForKey:@"To"];
        NSString * lastModified = [appointmentDic valueForKey:@"LastModified"];
        NSString * note = [appointmentDic valueForKey:@"Note"];
        NSString * status = [appointmentDic valueForKey:@"Status"];

    }


//    NSManagedObjectContext *context = [self managedObjectContext];
//    //Check if there is already a doctor account in coredata
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
//    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
//
//    // Create a new managed object
//    NSManagedObject *newDoctor;
//    if (doctorObject.count ==0) {
//        newDoctor = [NSEntityDescription insertNewObjectForEntityForName:@"DoctorInfo" inManagedObjectContext:context];
//    }else{
//        newDoctor = [doctorObject objectAtIndex:0];
//    }
//
//
//
//
//    NSError *error = nil;
//    // Save the object to persistent store
//    if (![context save:&error]) {
//        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
//    }else{
//        NSLog(@"Save success!");
//    }

}

#pragma mark - Connect to API function



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
    NSURLSession *defaultSession = [NSURLSession sharedSession];

    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //setup header and body for request
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"doctor26@gmail.com" forHTTPHeaderField:@"Email"];
    [urlRequest setValue:@"doctor199x" forHTTPHeaderField:@"Password"];
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
    return self.responseJSONData;
}
- (void)viewDidLoad {
    [super viewDidLoad];

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
        self.calendarViewToTopDistance.constant = 25;
    }else{
        self.calendarViewToTopDistance.constant = 40;
    }
    self.calendarView.layer.borderColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0].CGColor;
    self.calendarView.layer.borderWidth = 1.0f;
    [self.calendarView.layer setCornerRadius:5.0f];
    VRGCalendarView *calendar = [[VRGCalendarView alloc] init];

//    [calendar.layer setCornerRadius:5.0f];

    calendar.delegate = self;
    //set up layout for calendar subview
    calendar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.calendarView setBackgroundColor:[UIColor clearColor]];
//    UIImage *image = [UIImage imageNamed: @"blurbackgroundIOS.jpg"];
//    [self.backgroundImageView setImage:image];
    [self.calendarView addSubview:calendar];

    [self.calendarView  layoutIfNeeded];
}

-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated {

    //disable addnew appointment button if thereis no day selected
    [self.addNewAppointmentBarButton setEnabled:NO];
    //set add new appointment button to disable until user choose a date
    //hide listAppointMentInDayTableView if need
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionPush;
    animation.duration = 0.25;
    [self.listAppointMentInDayTableView.layer addAnimation:animation forKey:nil];
    [self.listAppointMentInDayTableView setHidden:YES];

    //set up height for listAppointMentInDayTableView to fit the calendar
    self.contentViewHeight.constant = targetHeight;
    [UIView animateWithDuration:0.35
                     animations:^{
                         [self.view layoutIfNeeded]; // Called on parent view
                     }];
    //declare some example date
    NSDateFormatter *dateFormaterToUTC = [[NSDateFormatter alloc] init];
    dateFormaterToUTC.timeStyle = NSDateFormatterNoStyle;
    dateFormaterToUTC.dateFormat = @"MM/dd/yyyy";
    [dateFormaterToUTC setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
//    [mmddccyy setLocale:[NSLocale systemLocale]];
    //get start datetime and finish datetime
    int firstWeekDay = [self firstWeekDayInMonth:calendarView.currentMonth];

    //get the unix mindate from current calendar's month
    NSString *startDate;
    if (firstWeekDay>1) {
        NSDate *previousMonth = [self offsetMonth:-1 withMonth:calendarView.currentMonth];
        int lastMonthNumDays = [self numDaysInMonth:previousMonth];
        int std = lastMonthNumDays - firstWeekDay +2;
        startDate = [NSString stringWithFormat:@"%d/%d/%d",[self month:previousMonth],std,[self year:previousMonth]];
    }else{
        startDate = [NSString stringWithFormat:@"%d/%d/%d",[self month:calendarView.currentMonth],01,[self year:calendarView.currentMonth]];
    }
//    NSLog(@"Start date  --------  %@",startDate);
    NSDate *minDate = [dateFormaterToUTC dateFromString:startDate];
    NSTimeInterval unixMinDate = [minDate timeIntervalSince1970];


    //get the unix maxdate from current calendar's month
    NSString *endDate;
    int currentMonthAndLastMonthTotalDays = [self numDaysInMonth:calendarView.currentMonth] + firstWeekDay -1;
    int lstd = (7 - currentMonthAndLastMonthTotalDays%7)%7;

    if (lstd==0) {
        endDate =[NSString stringWithFormat:@"%d/%d/%d",[self month:calendarView.currentMonth],[self numDaysInMonth:calendarView.currentMonth],[self year:calendarView.currentMonth]];
    }else{
        NSDate *nextMonth = [self offsetMonth:+1 withMonth:calendarView.currentMonth];
        endDate =[NSString stringWithFormat:@"%d/%d/%d",[self month:nextMonth],lstd,[self year:nextMonth]];
    }
//    NSLog(@"End date  --------  %@",endDate);
    NSDate *maxDate = [dateFormaterToUTC dateFromString:endDate];
    NSTimeInterval unixMaxDate = [maxDate timeIntervalSince1970];



    NSDictionary * responseDic = [self loadAppointmentDataFromAPIFrom:[NSString stringWithFormat:@"%f",unixMinDate*1000] and:[NSString stringWithFormat:@"%f",unixMaxDate*1000]];
    NSArray *appointment = [responseDic valueForKey:@"Appointments"];


    NSMutableArray *markedDatesArray = [[NSMutableArray alloc] init];
    for (int i=0; i<appointment.count; i++) {
        NSDictionary *currentAppointment = [appointment objectAtIndex:i];
        NSString *startTime = [currentAppointment valueForKey:@"From"];
        NSString *endTime = [currentAppointment valueForKey:@"To"];

        NSDate *startAppointMentTime = [NSDate dateWithTimeIntervalSince1970:[startTime doubleValue]/1000];
        NSDate *endAppointMentTime = [NSDate dateWithTimeIntervalSince1970:[endTime doubleValue]/1000];
        //add appoint date to marked date array in calendarView
        [markedDatesArray addObject:startAppointMentTime];

        NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
        [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatterToLocal setDateFormat:@"HH:mm:SS.SSS"];

        NSLog(@"----------------------%@",[dateFormatterToLocal stringFromDate:startAppointMentTime]);
        NSLog(@"----------------------%@",[dateFormatterToLocal stringFromDate:endAppointMentTime]);

    }


    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    if (month==[calendar component:NSCalendarUnitMonth fromDate:date] && self.markedDayList.count ==0) {
        
        self.markedDayList = markedDatesArray;
        [calendarView markDates:self.markedDayList];
    }


    //check if today is marked date
    BOOL isMarkedDate = NO;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    
    NSString *today = [dateFormatter stringFromDate:[NSDate date]];

    //set enable for add new appointment bar button if the current month is showing in first time
    if ([[dateFormatter stringFromDate:calendarView.currentMonth] isEqual:today]) {
        [self.addNewAppointmentBarButton setEnabled:YES];
    }
    for (int runIndex = 0; runIndex <self.markedDayList.count; runIndex ++) {
        NSString *currentDate = [dateFormatter stringFromDate:[self.markedDayList objectAtIndex:runIndex]];
        if ([today isEqual:currentDate]) {
            isMarkedDate = YES;
        }
    }

    //show list appoint for today
    if (isMarkedDate && [[dateFormatter stringFromDate:calendarView.currentMonth] isEqual:today]) {
        animation.duration = 0.35;
        [self.listAppointMentInDayTableView.layer addAnimation:animation forKey:nil];
        [self.listAppointMentInDayTableView setHidden:NO];

    }
}

-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date {
    [self.addNewAppointmentBarButton setEnabled:YES];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];

    NSLog(@"Selected date = %@",[dateFormatter stringFromDate:date]);
    self.chosenDate =[dateFormatter stringFromDate:date];

    //check if chosen date is marked date or not
    BOOL isMarkedDate = NO;
    for (int runIndex = 0; runIndex <self.markedDayList.count; runIndex ++) {
        NSString *currentDate = [dateFormatter stringFromDate:[self.markedDayList objectAtIndex:runIndex]];
        if ([self.chosenDate isEqual:currentDate]) {
            isMarkedDate = YES;
        }
    }

    //if the chosen date is also a marked date then show the list appointment in chosenday

    //animation to show or hide listAppointMentInDayTableView
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionPush;
    if (isMarkedDate) {
        animation.duration = 0.35;
        [self.listAppointMentInDayTableView.layer addAnimation:animation forKey:nil];
        [self.listAppointMentInDayTableView setHidden:NO];
        
    }else{
        animation.duration = 0.25;
        [self.listAppointMentInDayTableView.layer addAnimation:animation forKey:nil];
        [self.listAppointMentInDayTableView setHidden:YES];
    }
    
//    [self performSegueWithIdentifier:@"showAppointment" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)addNewAppointment:(id)sender{
    [self performSegueWithIdentifier: @"addNewAppointment" sender: self];
}

#pragma mark - Handle Calendar date time
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"appointmentDetailCell" ];
     if(cell == nil)
     {
         cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:@"appointmentDetailCell"];
         
     }
      // Configure the cell...
     cell.textLabel.text = @" Pham Duc Thang";
     cell.detailTextLabel.text = @"06-June-2016";

     cell.preservesSuperviewLayoutMargins = NO;
     cell.separatorInset = UIEdgeInsetsZero;
     cell.layoutMargins = UIEdgeInsetsZero;


     return cell;
 }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    [self performSegueWithIdentifier:@"showDetalAppointment" sender:self];
    [self.listAppointMentInDayTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"showAppointmentDetail"])
    {
        // Get reference to the destination view controller
        UINavigationController *nav = [segue destinationViewController];
        AppointmentViewDetailViewController *appointmentDetailViewController = (AppointmentViewDetailViewController*)nav.topViewController;
        // Pass any objects to the view controller here, like...
        
    }
    if ([[segue identifier] isEqualToString:@"addNewAppointment"])
    {
        // Get reference to the destination view controller
//        UINavigationController *nav = [segue destinationViewController];
        PatientsTableViewController *patientTableViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        patientTableViewController.isAppointmentViewDetailPatient = @"addNewAppointment";
    }
}


@end
