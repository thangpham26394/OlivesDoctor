//
//  AppointmentViewController.m
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 6/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "AppointmentViewController.h"
#import "SWRevealViewController.h"
#import "PatientsTableViewController.h"
#import "AppointmentViewDetailViewController.h"

@interface AppointmentViewController ()
@property (weak, nonatomic) IBOutlet UIView *calendarView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarViewToTopDistance;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UITableView *listAppointMentInDayTableView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property(strong,nonatomic) NSMutableArray * markedDayList;
@property(strong,nonatomic) NSString * chosenDate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addNewAppointmentBarButton;

-(IBAction)addNewAppointment:(id)sender;
@end

@implementation AppointmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.markedDayList = [[NSMutableArray alloc] init];

    //setup listAppointMentInDayTableView
    [self.listAppointMentInDayTableView.layer setCornerRadius:5.0f];
    [self.listAppointMentInDayTableView setShowsVerticalScrollIndicator:NO];
    [self.listAppointMentInDayTableView setSeparatorColor:[UIColor colorWithRed:0/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]];
    [self.listAppointMentInDayTableView setHidden:YES];

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
        self.calendarViewToTopDistance.constant = 50;
    }
    VRGCalendarView *calendar = [[VRGCalendarView alloc] init];

    [calendar.layer setCornerRadius:5.0f];

    calendar.delegate = self;
    //set up layout for calendar subview
    calendar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.calendarView setBackgroundColor:[UIColor clearColor]];
    UIImage *image = [UIImage imageNamed: @"blurbackgroundIOS.jpg"];
    [self.backgroundImageView setImage:image];
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
    NSDateFormatter *mmddccyy = [[NSDateFormatter alloc] init];
    mmddccyy.timeStyle = NSDateFormatterNoStyle;
    mmddccyy.dateFormat = @"MM/dd/yyyy";
    NSDate *d1 = [mmddccyy dateFromString:@"06/06/2016"];
    NSDate *d2 = [mmddccyy dateFromString:@"06/07/2017"];
    NSDate *d3 = [mmddccyy dateFromString:@"05/08/2015"];
    NSDate *d4 = [mmddccyy dateFromString:@"07/09/2016"];
    NSDate *d5 = [mmddccyy dateFromString:@"05/10/2016"];
    NSDate *d6 = [mmddccyy dateFromString:@"08/13/2016"];
    NSDate *d7 = [mmddccyy dateFromString:@"07/14/2016"];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    if (month==[calendar component:NSCalendarUnitMonth fromDate:date] && self.markedDayList.count ==0) {
        
        self.markedDayList = [NSMutableArray arrayWithObjects:d1,d2,d3,d4,d5,d6,d7,nil];
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
        UINavigationController *nav = [segue destinationViewController];
        PatientsTableViewController *patientTableViewController = (PatientsTableViewController*)nav.topViewController;
        // Pass any objects to the view controller here, like...
        patientTableViewController.isAppointmentViewDetailPatient = @"addNewAppointment";
    }
}


@end
