//
//  HomeViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 6/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "HomeViewController.h"
#import "SWRevealViewController.h"
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



//    NSString * doctorBirthDay = [doctor valueForKey:@"birthday"];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
//    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
//
//    NSDate *reverseDate = [NSDate dateWithTimeIntervalSince1970:[doctorBirthDay doubleValue]];
//    self.nameLabel.text =     [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:reverseDate] ];
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
