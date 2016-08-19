//
//  AddNewDiaryViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/diary"
#define APIURLEDIT @"http://olive.azurewebsites.net/api/diary?Id="
#import "AddNewDiaryViewController.h"
#import <CoreData/CoreData.h>



@interface AddNewDiaryViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;

@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;

- (IBAction)addOrUpdateDiarryAction:(id)sender;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@end

@implementation AddNewDiaryViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)saveDiaryToCoreData{

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Diary"];
    NSMutableArray *diaryObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *diary;

    if (diaryObject.count >0) {
        //convert selected from to time to UTC
        NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [formatter setLocale:[NSLocale systemLocale]];
        [formatter setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];

        NSDate *convertDateTime = [formatter dateFromString:[formatter stringFromDate:self.timePicker.date]];
        NSTimeInterval dateTimeUNIX = [convertDateTime timeIntervalSince1970];

        for (int index=0; index < diaryObject.count; index++) {
            diary = [diaryObject objectAtIndex:index];
            //find out the diary in coredata that have same id with selected diary to update
            if ([[diary valueForKey:@"id"] isEqual:[NSString stringWithFormat:@"%@",[self.selectedDiary objectForKey:@"Id"] ]]) {
                [diary setValue: [NSString stringWithFormat:@"%f",dateTimeUNIX*1000] forKey:@"time"];
                [diary setValue: self.noteTextView.text forKey:@"note"];
            }

        }
    }


    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save Medical Note success!");
    }
}

#pragma mark - Connect to API function

-(void)editDiaryAPI{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURLEDIT,[self.selectedDiary objectForKey:@"Id"]]];
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

    NSDate *convertdateTime = [formatter dateFromString:[formatter stringFromDate:self.timePicker.date]];
    NSTimeInterval dateTimeUNIX = [convertdateTime timeIntervalSince1970];

    NSDictionary *account = @{
                              @"Time":[NSString stringWithFormat:@"%f",dateTimeUNIX*1000],
                              @"Note":self.noteTextView.text,
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
                                                  [self saveDiaryToCoreData];
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


-(void)addNewDiaryNoteAPI{

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

    NSDate *convertDateTime = [formatter dateFromString:[formatter stringFromDate:self.timePicker.date]];

    NSTimeInterval dateTimeUNIX = [convertDateTime timeIntervalSince1970];




    NSDictionary *account = @{
                              @"Time":[NSString stringWithFormat:@"%f",dateTimeUNIX*1000],
                              @"Note":self.noteTextView.text,
                              @"Target" : self.selectedPatientID
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


#pragma mark - Handle notification

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
        [self.scrollView scrollRectToVisible:self.noteTextView.frame animated:YES];
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
    [self.noteTextView resignFirstResponder];
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
    self.timePicker.backgroundColor = [UIColor whiteColor];
    self.timePicker.layer.cornerRadius = 5.0f;
    self.timePicker.layer.masksToBounds = YES;

    self.noteTextView.layer.cornerRadius = 5.0f;

    //check if this view is used for update medical Note or not
    if (self.selectedDiary !=nil) {
        self.noteTextView.text = [self.selectedDiary objectForKey:@"Note"];

        //set up dateformater to local time
        NSDateFormatter * dateFormatToLocal = [[NSDateFormatter alloc] init];
        [dateFormatToLocal setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatToLocal setLocale:[NSLocale systemLocale]];
        [dateFormatToLocal setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];


        NSDate *dateTime = [NSDate dateWithTimeIntervalSince1970:[[self.selectedDiary objectForKey:@"Time"] doubleValue] /1000];

        dateTime = [dateFormatToLocal dateFromString:[dateFormatToLocal stringFromDate:dateTime]];
        self.timePicker.date = dateTime;
    }

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)addOrUpdateDiarryAction:(id)sender {
    //start animation
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];


    if (self.selectedDiary !=nil) {
        //this view is used for edit prescription
        [self editDiaryAPI];
    }else{
        //this view is used for add new prescription
        [self addNewDiaryNoteAPI];
    }

    //stop animation
    [self.activityIndicator stopAnimating];
    [self.backgroundView removeFromSuperview];

    [self.navigationController popViewControllerAnimated:YES];
}
@end
