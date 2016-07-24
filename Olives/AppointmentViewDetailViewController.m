//
//  AppointmentViewDetailViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "AppointmentViewDetailViewController.h"
#import <CoreData/CoreData.h>

@interface AppointmentViewDetailViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UILabel *customerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UILabel *customerPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *customerAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeOfServiceLabel;
@property (weak, nonatomic) IBOutlet UILabel *appointmentTimeLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
-(IBAction)cancel:(id)sender;
-(IBAction)edit:(id)sender;

@end

@implementation AppointmentViewDetailViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(NSDictionary *)getAppointmentFromID:(NSString *)appointmentID{
    NSDictionary *appointmentDic;
    //get all appointment from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Appointment"];
    NSMutableArray *appointmentObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *appointment;

    for (int index=0; index < appointmentObject.count; index++) {
        appointment = [appointmentObject objectAtIndex:index];
        //check if current appointment is appointment with gotten ID
        if ([[appointment valueForKey:@"appointmentID"] isEqual:self.appointmentID]) {
            //pass the appoinment from coredata to appointmentDic
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

            appointmentDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [appointment valueForKey:@"appointmentID" ],@"Id",
                                            [appointment valueForKey:@"dateCreated" ],@"Created",
                                            dater,@"Dater",
                                            maker,@"Maker",
                                            [appointment valueForKey:@"from" ],@"From",
                                            [appointment valueForKey:@"to" ],@"To",
                                            [appointment valueForKey:@"lastModified" ],@"LastModified",
                                            [appointment valueForKey:@"note" ],@"Note",
                                            [appointment valueForKey:@"status" ],@"Status",
                                            nil];
        }


    }


    return  appointmentDic;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width/2;
    self.avatarImage.clipsToBounds = YES;
    self.editButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:153/255.0 blue:153/255.0 alpha:1.0];
    self.cancelButton.backgroundColor = [UIColor colorWithRed:255/255.0 green:99/255.0 blue:71/255.0 alpha:1.0];

    //display information about selected appointment
    NSDictionary *selectedAppointment = [self getAppointmentFromID:self.appointmentID];
    if (selectedAppointment != nil) {
        NSString *patientId;
        //check if dater or maker is doctor
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
        NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        NSManagedObject *doctor = [doctorObject objectAtIndex:0];
        if ([[doctor valueForKey:@"doctorID"] isEqual:[NSString stringWithFormat:@"%@",[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"Id"]]]) {
            //if doctor is dater then patient is maker
            self.customerNameLabel.text = [NSString stringWithFormat:@"%@ %@",[[selectedAppointment objectForKey:@"Maker"] objectForKey:@"FirstName"],[[selectedAppointment objectForKey:@"Maker"] objectForKey:@"LastName"]];
            patientId = [[selectedAppointment objectForKey:@"Maker"] objectForKey:@"Id"];
        }else{
            //patient is dater
            self.customerNameLabel.text = [NSString stringWithFormat:@"%@ %@",[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"FirstName"],[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"LastName"]];
            patientId = [[selectedAppointment objectForKey:@"Dater"] objectForKey:@"Id"];
        }
        self.appointmentTimeLabel.text = [NSString stringWithFormat:@"%@ %@",[selectedAppointment objectForKey:@"From"],[selectedAppointment objectForKey:@"To"]];
        self.noteLabel.text = [selectedAppointment objectForKey:@"Note"];

        //get patient infor from coredata
        fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
        NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        NSManagedObject *patient;

        for (int index = 0; index<patientObject.count; index++) {
            patient = [patientObject objectAtIndex:index];
            //check if current patient is patient in appointment
            if ([[patient valueForKey:@"patientId"] isEqual:patientId]) {
                self.avatarImage.image = [UIImage imageWithData:[patient valueForKey:@"photo"]];
                self.customerPhoneLabel.text = [patient valueForKey:@"phone"];
                self.customerAddressLabel.text = [patient valueForKey:@"address"];
                self.emailLabel.text = [patient valueForKey:@"email"];
                //self.customerAddressLabel.text = [patient valueForKey:@"email"];
            }
        }


    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)cancel:(id)sender{

}

-(IBAction)edit:(id)sender{

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
