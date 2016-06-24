//
//  AppointmentViewController.m
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 6/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "AppointmentViewController.h"
#import "SWRevealViewController.h"

@interface AppointmentViewController ()
@property (weak, nonatomic) IBOutlet UIView *calendarView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarViewToBottomDistance;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

@end

@implementation AppointmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    SWRevealViewController *revealViewController = self.revealViewController;

    if (revealViewController) {
        [self.menuButton setTarget:self.revealViewController];
        [self.menuButton setAction:@selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    if ( [[UIScreen mainScreen] bounds].size.height == 568) {
        self.calendarViewToBottomDistance.constant = 120;
    }else{
        self.calendarViewToBottomDistance.constant = 170;
    }
    VRGCalendarView *calendar = [[VRGCalendarView alloc] init];
    [calendar.layer setCornerRadius:10.0f];
    calendar.delegate = self;
    //set up layout for calendar subview
    calendar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.calendarView setBackgroundColor:[UIColor clearColor]];
    UIImage *image = [UIImage imageNamed: @"backgroundIOS.jpeg"];
    [self.backgroundImageView setImage:image];
    [self.calendarView addSubview:calendar];
    [self.calendarView  addConstraint:[NSLayoutConstraint constraintWithItem:calendar
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.calendarView
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.0
                                                                    constant:0.0]];

    [self.calendarView  addConstraint:[NSLayoutConstraint constraintWithItem:calendar
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.calendarView
                                                                   attribute:NSLayoutAttributeLeading
                                                                  multiplier:1.0
                                                                    constant:0.0]];

    [self.calendarView  addConstraint:[NSLayoutConstraint constraintWithItem:calendar
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.calendarView
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.0
                                                                    constant:0.0]];

    [self.calendarView  addConstraint:[NSLayoutConstraint constraintWithItem:calendar
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.calendarView
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0
                                                                    constant:0.0]];
    [self.calendarView  layoutIfNeeded];
}

-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated {
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
    NSDate *d7 = [mmddccyy dateFromString:@"06/02/2016"];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    if (month==[calendar component:NSCalendarUnitMonth fromDate:date]) {
        NSArray *dates = [NSArray arrayWithObjects:d1,d2,d3,d4,d5,d6,d7,nil];
        [calendarView markDates:dates];
    }
}

-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"dd MMMM yyyy"];
    NSLog(@"Selected date = %@",[dateFormatter stringFromDate:date]);
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

@end
