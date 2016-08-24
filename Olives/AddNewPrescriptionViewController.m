//
//  AddNewPrescriptionViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/5/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/prescription"
#define APIURLEDIT @"http://olive.azurewebsites.net/api/medical/prescription?id="
#import "AddNewPrescriptionViewController.h"
#import <CoreData/CoreData.h>


@interface AddNewPrescriptionViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITextView *prescriptionName;
@property (weak, nonatomic) IBOutlet UITextView *noteTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *fromDateTimePicker;
@property (weak, nonatomic) IBOutlet UIDatePicker *toDateTimePicker;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
- (IBAction)savePrescriptionAction:(id)sender;
@property (weak, nonatomic) UITextView *activeField;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@end

@implementation AddNewPrescriptionViewController

- (IBAction)textViewDidBeginEditing:(UITextView *)sender
{
    self.activeField = sender;
}

- (IBAction)textViewDidEndEditing:(UITextView *)sender
{
    self.activeField = nil;
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
    if (!CGRectContainsPoint(aRect, self.saveButton.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

-(void) setupGestureRecognizerToDisMissKeyBoard {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureToDisMissKeyBoard:)];
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)handleTapGestureToDisMissKeyBoard:(UIPanGestureRecognizer *)recognizer{
    [self.activeField resignFirstResponder];
}


#pragma mark - View delegate
- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    [self setupGestureRecognizerToDisMissKeyBoard];
}

- (void)viewWillDisappear:(BOOL)animated {

    [self deregisterFromKeyboardNotifications];

    [super viewWillDisappear:animated];
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.translucent = NO;
    self.saveButton.backgroundColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];
    self.contentViewHeight.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;
    self.fromDateTimePicker.backgroundColor = [UIColor whiteColor];
    self.fromDateTimePicker.layer.cornerRadius = 5.0f;
    self.fromDateTimePicker.layer.masksToBounds = YES;

    self.toDateTimePicker.backgroundColor = [UIColor whiteColor];
    self.toDateTimePicker.layer.cornerRadius = 5.0f;
    self.toDateTimePicker.layer.masksToBounds = YES;

    self.prescriptionName.layer.cornerRadius = 5.0f;
    self.noteTextField.layer.cornerRadius = 5.0f;


    //check if this view is used for update prescription or not
    if (self.selectedMedicalRecordId ==nil) {
        self.prescriptionName.text = [self.selectedPrescription objectForKey:@"Name"];
        self.noteTextField.text = [self.selectedPrescription objectForKey:@"Note"];

        //set up dateformater to local time
        NSDateFormatter * dateFormatToLocal = [[NSDateFormatter alloc] init];
        [dateFormatToLocal setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatToLocal setLocale:[NSLocale systemLocale]];
        [dateFormatToLocal setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];


        NSDate *fromDate = [NSDate dateWithTimeIntervalSince1970:[[self.selectedPrescription objectForKey:@"From"] doubleValue] /1000];
        NSDate *toDate = [NSDate dateWithTimeIntervalSince1970:[[self.selectedPrescription objectForKey:@"To"] doubleValue] /1000];

        fromDate = [dateFormatToLocal dateFromString:[dateFormatToLocal stringFromDate:fromDate]];
        toDate = [dateFormatToLocal dateFromString:[dateFormatToLocal stringFromDate:toDate]];

        self.fromDateTimePicker.date = fromDate;
        self.toDateTimePicker.date = toDate;

    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Connect to API function

-(void)addNewPrescriptionAPI{

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

    //convert selected from to time to UTC
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];

    NSDate *convertFromDateTime = [formatter dateFromString:[formatter stringFromDate:self.fromDateTimePicker.date]];
    NSDate *convertToDateTime = [formatter dateFromString:[formatter stringFromDate:self.toDateTimePicker.date]];
    NSTimeInterval fromDateTimeUNIX = [convertFromDateTime timeIntervalSince1970];
    NSTimeInterval toDateTimeUNIX = [convertToDateTime timeIntervalSince1970];


    
    NSDictionary *account = @{
                              @"Name" :  self.prescriptionName.text,
                              @"From" : [NSString stringWithFormat:@"%f",fromDateTimeUNIX*1000],
                              @"To":[NSString stringWithFormat:@"%f",toDateTimeUNIX*1000],
                              @"Note":self.noteTextField.text,
                              @"MedicalRecord":self.selectedMedicalRecordId,
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

-(void)editwPrescriptionAPI{

    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURLEDIT,[self.selectedPrescription objectForKey:@"Id"]]];
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
    //create JSON data to post to API

    //convert selected from to time to UTC
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];

    NSDate *convertFromDateTime = [formatter dateFromString:[formatter stringFromDate:self.fromDateTimePicker.date]];
    NSDate *convertToDateTime = [formatter dateFromString:[formatter stringFromDate:self.toDateTimePicker.date]];
    NSTimeInterval fromDateTimeUNIX = [convertFromDateTime timeIntervalSince1970];
    NSTimeInterval toDateTimeUNIX = [convertToDateTime timeIntervalSince1970];



    NSDictionary *account = @{
                              @"Name" :  self.prescriptionName.text,
                              @"From" : [NSString stringWithFormat:@"%f",fromDateTimeUNIX*1000],
                              @"To":[NSString stringWithFormat:@"%f",toDateTimeUNIX*1000],
                              @"Note":self.noteTextField.text,
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
                                                  [self savePrescriptionToCoreData];
                                              }else{


                                              }

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


#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)savePrescriptionToCoreData{

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Prescriptions"];
    NSMutableArray *prescriptionObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *prescription;

    if (prescriptionObject.count >0) {

        //convert selected from to time to UTC
        NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [formatter setLocale:[NSLocale systemLocale]];
        [formatter setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];

        NSDate *convertFromDateTime = [formatter dateFromString:[formatter stringFromDate:self.fromDateTimePicker.date]];
        NSDate *convertToDateTime = [formatter dateFromString:[formatter stringFromDate:self.toDateTimePicker.date]];
        NSTimeInterval fromDateTimeUNIX = [convertFromDateTime timeIntervalSince1970];
        NSTimeInterval toDateTimeUNIX = [convertToDateTime timeIntervalSince1970];

        for (int index=0; index < prescriptionObject.count; index++) {
            prescription = [prescriptionObject objectAtIndex:index];
            //find out the prescription in coredata that have same id with selected prescription to update
            if ([[prescription valueForKey:@"prescriptionID"] isEqual:[NSString stringWithFormat:@"%@",[self.selectedPrescription objectForKey:@"Id"]]]) {
                [prescription setValue: [NSString stringWithFormat:@"%f",fromDateTimeUNIX*1000] forKey:@"from"];
                [prescription setValue: [NSString stringWithFormat:@"%f",toDateTimeUNIX*1000] forKey:@"to"];
                [prescription setValue: self.prescriptionName.text forKey:@"name"];
                [prescription setValue: self.noteTextField.text forKey:@"note"];

            }

        }
    }


    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save Prescription success!");
    }

}





/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//show alert message for error
-(void)showAlertError:(NSString *)errorString{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:errorString
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {}];
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}


- (IBAction)savePrescriptionAction:(id)sender {
    if (self.canEdit) {
        if (self.selectedMedicalRecordId ==nil) {
            //this view is used for edit prescription
            [self editwPrescriptionAPI];
        }else{
            //this view is used for add new prescription
            [self addNewPrescriptionAPI];
        }
    }else{
        [self showAlertError:@"You don't have permission in this medical record"];
    }


    [self.navigationController popViewControllerAnimated:YES];
}
@end
