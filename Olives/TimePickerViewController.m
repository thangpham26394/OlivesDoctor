//
//  TimePickerViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/12/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/appointment"
#define APIURLEDIT @"http://olive.azurewebsites.net/api/appointment?id="
#import "TimePickerViewController.h"
#import "PatientTableViewCell.h"
#import "PatientsTableViewController.h"
#import <CoreData/CoreData.h>
@interface TimePickerViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *dateTimePickerFrom;
@property (weak, nonatomic) IBOutlet UIDatePicker *dateTimePickerTo;

@property (weak, nonatomic) IBOutlet UITextView *noteLabel;

-(IBAction)sendRequestButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (weak, nonatomic) IBOutlet UIView *chosingPatient;
@property (weak, nonatomic) IBOutlet UIImageView *selectedPatientAvatar;
@property (weak, nonatomic) IBOutlet UILabel *selectedPatientName;
@property (weak, nonatomic) IBOutlet UILabel *selectedPatientAddress;
@property (weak, nonatomic) IBOutlet UILabel *selectedPatientEmail;
@property (weak, nonatomic) IBOutlet UILabel *selectedPatientPhone;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *editOrAceptAppointment;
- (IBAction)cancelPendingAppointment:(id)sender;
- (IBAction)editOrAcceptAppointmentButton:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightForDisplayMakerNote;
@property (weak, nonatomic) IBOutlet UITextView *makerNoteTextView;


@end

@implementation TimePickerViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}


#pragma mark - Configure scroll view

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {

        [textView resignFirstResponder];
        // Return FALSE so that the final '\n' character doesn't get added
        return NO;
    }
    // For any other character return TRUE so that the text gets added to the view
    return YES;
}

- (void)registerForKeyboardNotifications {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)deregisterFromKeyboardNotifications {

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    // If you are using Xcode 6 or iOS 7.0, you may need this line of code. There was a bug when you
    // rotated the device to landscape. It reported the keyboard as the wrong size as if it was still in portrait mode.
    kbRect = [self.view convertRect:kbRect fromView:nil];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, self.sendButton.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.sendButton.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

-(void) setupGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];

    [self.chosingPatient addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self performSegueWithIdentifier:@"chosingPatient" sender:self];
}

-(void) setupGestureRecognizerToDisMissKeyBoard {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureToDisMissKeyBoard:)];
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)handleTapGestureToDisMissKeyBoard:(UIPanGestureRecognizer *)recognizer{
    [self.noteLabel resignFirstResponder];
}

#pragma mark - View delegate
- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    self.navigationController.topViewController.title = self.chosenDate;
    [self registerForKeyboardNotifications];
    [self setupGestureRecognizerToDisMissKeyBoard];
}

- (void)viewWillDisappear:(BOOL)animated {

    [self deregisterFromKeyboardNotifications];

    [super viewWillDisappear:animated];
    
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
                              [appointment valueForKey:@"lastModifiedNote" ],@"LastModifiedNote",
                              nil];
        }


    }
    return  appointmentDic;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self.editOrAceptAppointment setBackgroundColor:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
    [self.makerNoteTextView setEditable:NO];
    self.scrollView.bounces = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.sendButton.backgroundColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];

    self.contentViewHeight.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;

    self.dateTimePickerFrom.backgroundColor = [UIColor whiteColor];
    self.dateTimePickerFrom.layer.cornerRadius = 5.0f;
    self.dateTimePickerFrom.layer.masksToBounds = YES;

    self.dateTimePickerTo.backgroundColor = [UIColor whiteColor];
    self.dateTimePickerTo.layer.cornerRadius = 5.0f;
    self.dateTimePickerTo.layer.masksToBounds = YES;

    self.chosingPatient.layer.cornerRadius = 5.0f;
    self.selectedPatientAvatar.layer.cornerRadius = self.selectedPatientAvatar.frame.size.width / 2;
    self.selectedPatientAvatar.layer.masksToBounds = YES;
    self.noteLabel.layer.cornerRadius = 5.0f;
    [self.noteLabel setShowsVerticalScrollIndicator:NO];
    self.makerNoteTextView.layer.cornerRadius = 5.0f;
    
    //format initial date time
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];

    //formt initial date
    NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormat setLocale:[NSLocale systemLocale]];
    [dateFormat setDateFormat:@"MM/dd/yyyy"];
    NSString *initialDate = [dateFormat stringFromDate:[dateFormat dateFromString:self.chosenDate]];

    //check if current view is for add new an appointment or edit an appointment
    if (self.appointmentID == nil) {

        //add new
        self.heightForDisplayMakerNote.constant = 0; //hide the textview display maker note
        [self.editOrAceptAppointment setHidden:YES];
        [self.cancelButton setHidden:YES];
        [self setupGestureRecognizer];
        //set up initial date time for dateTimePicker
        NSString *initialTime = [NSString stringWithFormat:@"%@ 00:00:00:000",initialDate];
        NSDate * date = [formatter dateFromString:initialTime];

        [self.dateTimePickerFrom setDate:date];
        [self.dateTimePickerTo setDate:date];

    }else if (self.isNotificationView){

        //if this view is used to show notification
        [self.editOrAceptAppointment setTitle:@"Accept" forState:UIControlStateNormal];
        self.dateTimePickerFrom.userInteractionEnabled = NO;
        self.dateTimePickerTo.userInteractionEnabled = NO;
        [self.editOrAceptAppointment setHidden:NO];
        [self.cancelButton setHidden:NO];
        NSDictionary *selectedAppointment = [self getAppointmentFromID:self.appointmentID];
        NSString *patientId;
        //check if dater or maker is doctor
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
        NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        NSManagedObject *doctor = [doctorObject objectAtIndex:0];

        if ([[doctor valueForKey:@"doctorID"] isEqual:[NSString stringWithFormat:@"%@",[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"Id"]]]) {
            //if doctor is dater then patient is maker
            self.selectedPatientName.text = [NSString stringWithFormat:@"%@ %@",[[selectedAppointment objectForKey:@"Maker"] objectForKey:@"FirstName"],[[selectedAppointment objectForKey:@"Maker"] objectForKey:@"LastName"]];
            patientId = [[selectedAppointment objectForKey:@"Maker"] objectForKey:@"Id"];
        }else{
            //patient is dater
            self.selectedPatientName.text = [NSString stringWithFormat:@"%@ %@",[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"FirstName"],[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"LastName"]];
            patientId = [[selectedAppointment objectForKey:@"Dater"] objectForKey:@"Id"];
        }
        self.makerNoteTextView.text = [selectedAppointment objectForKey:@"Note"];
        if ([selectedAppointment objectForKey:@"LastModifiedNote"] == [NSNull null] || [[selectedAppointment objectForKey:@"LastModifiedNote"] isEqualToString:@"<null>"]) {
            self.noteLabel.text =   @"";
        }else{
            self.noteLabel.text =   [selectedAppointment objectForKey:@"LastModifiedNote"];
        }

        //set up dateformater to local time
        NSDateFormatter * dateFormatToLocal = [[NSDateFormatter alloc] init];
        [dateFormatToLocal setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatToLocal setLocale:[NSLocale systemLocale]];
        [dateFormatToLocal setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];


        NSDate *fromDate = [NSDate dateWithTimeIntervalSince1970:[[selectedAppointment objectForKey:@"From"] doubleValue] /1000];
        NSDate *toDate = [NSDate dateWithTimeIntervalSince1970:[[selectedAppointment objectForKey:@"To"] doubleValue] /1000];

        fromDate = [dateFormatToLocal dateFromString:[dateFormatToLocal stringFromDate:fromDate]];
        toDate = [dateFormatToLocal dateFromString:[dateFormatToLocal stringFromDate:toDate]];
        self.dateTimePickerFrom.date = fromDate;
        self.dateTimePickerTo.date = toDate;

        //get patient infor from coredata
        fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
        NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        NSManagedObject *patient;

        for (int index = 0; index<patientObject.count; index++) {
            patient = [patientObject objectAtIndex:index];
            //check if current patient is patient in appointment
            if ([[patient valueForKey:@"patientId"] isEqual:patientId]) {
                self.selectedPatientAvatar.image = [UIImage imageWithData:[patient valueForKey:@"photo"]];
                self.selectedPatientPhone.text  = [patient valueForKey:@"phone"];
                self.selectedPatientAddress.text = [patient valueForKey:@"address"];
                self.selectedPatientEmail.text= [patient valueForKey:@"email"];
                //self.customerAddressLabel.text = [patient valueForKey:@"email"];
            }
        }



    }else{
        //edit an appointment
        //check if appointment selected is from patient or doctor
        if ([self.segmentUsing isEqual:@"PendingFromPatient"]) {
            [self.editOrAceptAppointment setTitle:@"Accept" forState:UIControlStateNormal];
            self.dateTimePickerFrom.userInteractionEnabled = NO;
            self.dateTimePickerTo.userInteractionEnabled = NO;
        }
        [self.editOrAceptAppointment setHidden:NO];
        [self.cancelButton setHidden:NO];
        //check if appointment selected is active or note
        if (self.isActiveAppointment) {
            //appointment is still active
            [self.editOrAceptAppointment setHidden:NO];
            [self.cancelButton setHidden:NO];
        }else{
            //appointment is not active anymore
            [self.editOrAceptAppointment setHidden:YES];
            [self.cancelButton setHidden:YES];
            [self.sendButton setHidden:YES];
            [self.noteLabel setEditable:NO];
            self.dateTimePickerFrom.userInteractionEnabled = NO;
            self.dateTimePickerTo.userInteractionEnabled = NO;
        }
        NSDictionary *selectedAppointment = [self getAppointmentFromID:self.appointmentID];
        NSString *patientId;
        //check if dater or maker is doctor
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
        NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        NSManagedObject *doctor = [doctorObject objectAtIndex:0];

        if ([[doctor valueForKey:@"doctorID"] isEqual:[NSString stringWithFormat:@"%@",[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"Id"]]]) {
            //if doctor is dater then patient is maker
            self.selectedPatientName.text = [NSString stringWithFormat:@"%@ %@",[[selectedAppointment objectForKey:@"Maker"] objectForKey:@"FirstName"],[[selectedAppointment objectForKey:@"Maker"] objectForKey:@"LastName"]];
            patientId = [[selectedAppointment objectForKey:@"Maker"] objectForKey:@"Id"];
        }else{
            //patient is dater
            self.selectedPatientName.text = [NSString stringWithFormat:@"%@ %@",[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"FirstName"],[[selectedAppointment objectForKey:@"Dater"] objectForKey:@"LastName"]];
            patientId = [[selectedAppointment objectForKey:@"Dater"] objectForKey:@"Id"];
        }
        self.makerNoteTextView.text = [selectedAppointment objectForKey:@"Note"];
        if ([selectedAppointment objectForKey:@"LastModifiedNote"] == [NSNull null] || [[selectedAppointment objectForKey:@"LastModifiedNote"] isEqualToString:@"<null>"]) {
            self.noteLabel.text =   @"";
        }else{
            self.noteLabel.text =   [selectedAppointment objectForKey:@"LastModifiedNote"];
        }

        //set up dateformater to local time
        NSDateFormatter * dateFormatToLocal = [[NSDateFormatter alloc] init];
        [dateFormatToLocal setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatToLocal setLocale:[NSLocale systemLocale]];
        [dateFormatToLocal setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];


        NSDate *fromDate = [NSDate dateWithTimeIntervalSince1970:[[selectedAppointment objectForKey:@"From"] doubleValue] /1000];
        NSDate *toDate = [NSDate dateWithTimeIntervalSince1970:[[selectedAppointment objectForKey:@"To"] doubleValue] /1000];

        fromDate = [dateFormatToLocal dateFromString:[dateFormatToLocal stringFromDate:fromDate]];
        toDate = [dateFormatToLocal dateFromString:[dateFormatToLocal stringFromDate:toDate]];
        self.dateTimePickerFrom.date = fromDate;
        self.dateTimePickerTo.date = toDate;

        //get patient infor from coredata
        fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
        NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        NSManagedObject *patient;

        for (int index = 0; index<patientObject.count; index++) {
            patient = [patientObject objectAtIndex:index];
            //check if current patient is patient in appointment
            if ([[patient valueForKey:@"patientId"] isEqual:patientId]) {
                self.selectedPatientAvatar.image = [UIImage imageWithData:[patient valueForKey:@"photo"]];
                self.selectedPatientPhone.text  = [patient valueForKey:@"phone"];
                self.selectedPatientAddress.text = [patient valueForKey:@"address"];
                self.selectedPatientEmail.text= [patient valueForKey:@"email"];
                //self.customerAddressLabel.text = [patient valueForKey:@"email"];
            }
        }

    }


}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Send request

-(void)sendRequestChangeAppointmentStatusToAPI:(NSInteger )status{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURLEDIT,self.appointmentID]];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    sessionConfig.timeoutIntervalForRequest = 5.0;
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

    //create JSON data to post to API
    NSDictionary *body = @{
                           @"Status" :[NSString stringWithFormat:@"%ld",(long)status], //set status to cancel status
                           @"Note" : self.noteLabel.text
                           };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsondata];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSError *parsJSONError = nil;
                                              if (data ==nil) {
                                                  UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Internet Error"
                                                                                                                 message:nil
                                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                                  UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                     style:UIAlertActionStyleDefault
                                                                                                   handler:^(UIAlertAction * action) {}];
                                                  [alert addAction:OKAction];
                                                  [self presentViewController:alert animated:YES completion:nil];
                                                  dispatch_semaphore_signal(sem);

                                                  return;
                                              }
                                              NSDictionary *errorDic = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              NSArray *errorArray = [errorDic objectForKey:@"Errors"];
                                              //                                              NSLog(@"\n\n\nError = %@",[errorArray objectAtIndex:0]);

                                              UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                                             message:[errorArray objectAtIndex:0]
                                                                                                      preferredStyle:UIAlertControllerStyleAlert];

                                              UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                 style:UIAlertActionStyleDefault
                                                                                               handler:^(UIAlertAction * action) {}];
                                              [alert addAction:OKAction];
                                              [self presentViewController:alert animated:YES completion:nil];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }

                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

-(void)sendRequestEditAppointmentToAPI{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURLEDIT,self.appointmentID]];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    sessionConfig.timeoutIntervalForRequest = 5.0;
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

    //convert selected from to time to UTC
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];

    NSDate *convertFromDateTime = [formatter dateFromString:[formatter stringFromDate:self.dateTimePickerFrom.date]];
    NSDate *convertToDateTime = [formatter dateFromString:[formatter stringFromDate:self.dateTimePickerTo.date]];
    NSTimeInterval fromDateTimeUNIX = [convertFromDateTime timeIntervalSince1970];
    NSTimeInterval toDateTimeUNIX = [convertToDateTime timeIntervalSince1970];


    //create JSON data to post to API
    NSDictionary *body = @{
                           @"From" :[NSString stringWithFormat:@"%f",fromDateTimeUNIX*1000],
                           @"To" :  [NSString stringWithFormat:@"%f",toDateTimeUNIX*1000],
                           @"Note" :self.noteLabel.text
                           };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsondata];

    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {

                                      }];
    [dataTask resume];

}




-(void)sendRequestCreateAppointmentToAPI{
    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];


//    sessionConfig.timeoutIntervalForRequest = 5.0;
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



    NSTimeInterval fromDateTimeUNIX = [self.dateTimePickerFrom.date timeIntervalSince1970];
    NSTimeInterval toDateTimeUNIX = [self.dateTimePickerTo.date timeIntervalSince1970];


    //create JSON data to post to API
    NSDictionary *body = @{
                              @"Dater" :  [NSString stringWithFormat:@"%@",[self.selectedPatient objectForKey:@"Id"]],
                              @"From" :[NSString stringWithFormat:@"%f",fromDateTimeUNIX*1000],
                              @"To" :  [NSString stringWithFormat:@"%f",toDateTimeUNIX*1000],
                              @"Note" :self.noteLabel.text
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsondata];

//    dispatch_semaphore_t    sem;
//    sem = dispatch_semaphore_create(0);

    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          //dispatch_semaphore_signal(sem);

                                      }];
    [dataTask resume];
    //start waiting until get response from API
    //dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);









}

-(IBAction)sendRequestButton:(id)sender{
    [self.noteLabel resignFirstResponder];
    //don't select patient yet
    if ([self.selectedPatient objectForKey:@"Id"] == nil) {
        [self showAlertViewForError:@"You must select a patient first!"];
    }else{
        //time start later than time end
        if ([self.dateTimePickerFrom.date timeIntervalSince1970] > [self.dateTimePickerTo.date timeIntervalSince1970]) {
            [self showAlertViewForError:@"Time start should be sooner than time end!"];
        }else{
            [self showAlertViewWhenSendRequest];
        }
    }
}


#pragma mark - alert view for action

-(void)showAlertViewForError:(NSString*)errorString{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:errorString
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {

                                                     }];

    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}


-(void)showAlertViewWhenSendRequest{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Request Sent"
                                                               message:@"Your Request will be sent to your patient soon"
                                                               preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              //sent request to API here
                                                              NSLog(@"OK Action!");
                                                              [self sendRequestCreateAppointmentToAPI];
                                                              [self.navigationController popViewControllerAnimated:YES];
                                                              
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * action) {
                                                         NSLog(@"cancel Action!");
                                                         NSLog(@"%@",self.dateTimePickerFrom.date);
                                                         NSLog(@"%@",self.dateTimePickerTo.date);
                                                     }];


    [alert addAction:OKAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showAlertViewWhenSendCancel{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure"
                                                                   message:@"This appointment will be canceled"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         //sent request to API here
                                                         NSLog(@"OK Action!");
                                                         [self sendRequestChangeAppointmentStatusToAPI:0];
                                                         [self.navigationController popViewControllerAnimated:YES];

                                                     }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             NSLog(@"cancel Action!");
                                                         }];


    [alert addAction:OKAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showAlertViewWhenSendAccept{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Confirm"
                                                                   message:@"Are you sure to accept this appointment"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         //sent request to API here
                                                         NSLog(@"OK Action!");
                                                         [self sendRequestChangeAppointmentStatusToAPI:2];
                                                         [self.navigationController popViewControllerAnimated:YES];

                                                     }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             NSLog(@"cancel Action!");
                                                         }];


    [alert addAction:OKAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}



-(void)showAlertViewWhenSendEdit{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure"
                                                                   message:@"This appointment will be edited"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         //sent request to API here
                                                         NSLog(@"OK Action!");
                                                         [self sendRequestEditAppointmentToAPI];
                                                         [self.navigationController popViewControllerAnimated:YES];

                                                     }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             NSLog(@"cancel Action!");
                                                         }];


    [alert addAction:OKAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Navigation
- (IBAction)unwindToTimePicker:(UIStoryboardSegue *)unwindSegue
{
    UITableViewController* sourceViewController = unwindSegue.sourceViewController;

    if ([sourceViewController isKindOfClass:[PatientsTableViewController class]])
    {
        //get doctor email and password from coredata
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
        NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        for (int index=0; index <patientObject.count; index++) {
            NSManagedObject *patient = [patientObject objectAtIndex:index];
            if ([ [NSString stringWithFormat:@"%@",[self.selectedPatient objectForKey:@"Id"]] isEqual:[patient valueForKey:@"patientId"]]) {
                self.selectedPatientAvatar.image = [UIImage imageWithData:[patient valueForKey:@"photo"]];
                self.selectedPatientName.text = [NSString stringWithFormat:@"%@ %@",[patient valueForKey:@"firstName"],[patient valueForKey:@"lastName"]];
                self.selectedPatientEmail.text = [patient valueForKey:@"email"];
                self.selectedPatientPhone.text = [patient valueForKey:@"phone"];
                self.selectedPatientAddress.text = [patient valueForKey:@"address"];
            }


        }


    }

}
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"chosingPatient"])
    {
        PatientsTableViewController *patientTableViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        patientTableViewController.isAppointmentViewDetailPatient = self.chosenDate;
    }
}


- (IBAction)cancelPendingAppointment:(id)sender {
    [self showAlertViewWhenSendCancel];
}

- (IBAction)editOrAcceptAppointmentButton:(id)sender {
    //time start later than time end
    if ([self.dateTimePickerFrom.date timeIntervalSince1970] > [self.dateTimePickerTo.date timeIntervalSince1970]) {
        [self showAlertViewForError:@"Time start should be sooner than time end!"];
    }else{
        if (self.isNotificationView) {
            [self showAlertViewWhenSendAccept];
        }
        else if ([self.segmentUsing isEqual:@"PendingFromPatient"]) {
            [self showAlertViewWhenSendAccept];
        }else{
            [self showAlertViewWhenSendEdit];
        }

    }


}
@end
