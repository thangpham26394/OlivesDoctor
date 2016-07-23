//
//  EditProfileViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/22/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/doctor/profile"
#import "EditProfileViewController.h"
#import "SWRevealViewController.h"
#import <CoreData/CoreData.h>
@interface EditProfileViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

//edit informations
@property (weak, nonatomic) UITextField *activeField;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *brandnewPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmNewPasswordTextField;

@property (weak, nonatomic) IBOutlet UITextField *birthdayTextFieldDay;
@property (weak, nonatomic) IBOutlet UITextField *birthdayTextFieldMonth;
@property (weak, nonatomic) IBOutlet UITextField *birthdayTextFieldYear;



@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSegment;
@property (weak, nonatomic) IBOutlet UIView *genderBackground;
@property (weak, nonatomic) IBOutlet UILabel *mistakeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (strong,nonatomic) NSDictionary *responseJSONData ;
@property (strong,nonatomic) NSDictionary *mistake;

- (IBAction)updateProfile:(id)sender;










@end

@implementation EditProfileViewController

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}


- (IBAction)textFieldDidBeginEditing:(UITextField *)sender
{
    self.activeField = sender;
}

- (IBAction)textFieldDidEndEditing:(UITextField *)sender
{
    self.activeField = nil;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textfield {
    [self.activeField resignFirstResponder];
    return YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scrollView.bounces = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.avatar.layer.cornerRadius = self.avatar.frame.size.width / 2;
    
    //Set up for slide view
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.menuButton setTarget:self.revealViewController];
        [self.menuButton setAction:@selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    self.contentViewHeight.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;

    [self.saveButton.layer setCornerRadius:self.saveButton.frame.size.height/2+1];
    self.saveButton.backgroundColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];
    self.genderBackground.layer.cornerRadius = 5.0f;

    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    self.avatar.image = [UIImage imageWithData:[doctor valueForKey:@"photoURL"]];
    //set place holder text for each text field
    self.firstNameTextField.text = [doctor valueForKey:@"firstName"];
    self.lastNameTextField.text = [doctor valueForKey:@"lastName"];
    
    NSString *birthdayUnixTime = [doctor valueForKey:@"birthday"];
    //convert time interval to NSDate type
    NSDate *birthdayUNIXDate = [NSDate dateWithTimeIntervalSince1970:[birthdayUnixTime doubleValue]/1000];
    //convert to system datetime
    NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];
    //convert date to system date time
    NSDate *birthdaySystemDate = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:birthdayUNIXDate]];
    // Extract the day number (14)
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:birthdaySystemDate];

    self.birthdayTextFieldDay.text = [NSString stringWithFormat:@"%ld",(long)[components day]];
    self.birthdayTextFieldMonth.text = [NSString stringWithFormat:@"%ld",(long)[components month]];
    self.birthdayTextFieldYear.text = [NSString stringWithFormat:@"%ld",(long)[components year]];
    self.phoneTextField.text = [doctor valueForKey:@"phone"];
    NSString *gender = [doctor valueForKey:@"gender"];
    if ([gender  isEqual:@"0"]) {
        self.genderSegment.selectedSegmentIndex = 0;
    }else{
        self.genderSegment.selectedSegmentIndex = 1;
    }
    self.addressTextField.text = [doctor valueForKey:@"address"];


    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];

}

- (void)viewWillDisappear:(BOOL)animated {

    [self deregisterFromKeyboardNotifications];

    [super viewWillDisappear:animated];
    
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
    //kbRect = [self.view convertRect:kbRect fromView:nil];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)updateDoctorProfileToAPIWith:(NSString*)email and :(NSString*)password{
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
    //setup header and body for request
    [urlRequest setHTTPMethod:@"PUT"];
    [urlRequest setValue:email forHTTPHeaderField:@"Email"];
    [urlRequest setValue:password  forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];


    //get birthday string UNIX time from user input
    NSString *userInputBirthday = [NSString stringWithFormat:@"%@/%@/%@",self.birthdayTextFieldMonth.text,self.birthdayTextFieldDay.text,self.birthdayTextFieldYear.text];
    // dateformater to convert to UTC time zone
    NSDateFormatter *dateFormaterToUTC = [[NSDateFormatter alloc] init];
    dateFormaterToUTC.timeStyle = NSDateFormatterNoStyle;
    dateFormaterToUTC.dateFormat = @"MM/dd/yyyy";
    [dateFormaterToUTC setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSDate *userInputDate = [dateFormaterToUTC dateFromString:userInputBirthday];
    NSTimeInterval birthdayUNIXTime = [userInputDate timeIntervalSince1970];



    //create JSON data to post to API
    NSDictionary *account = @{
                              @"FirstName" :  self.firstNameTextField.text,
                              @"LastName" :self.lastNameTextField.text,
                              @"Birthday" : [NSString stringWithFormat:@"%f",birthdayUNIXTime *1000] ,
                              @"Phone" :self.phoneTextField.text,
                              @"Gender" :  [NSString stringWithFormat:@"%ld",(long)self.genderSegment.selectedSegmentIndex],
                              @"Address" :self.addressTextField.text,
                              @"Password" :  self.brandnewPasswordTextField.text
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
                                              self.mistake = nil;
                                              [self updateNewProfileToCoreData];
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
//                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
//                                              NSLog(@"\n\n\nError = %@",text);
                                              NSError *parsJSONError = nil;
                                              self.mistakeLabel.textColor = [UIColor redColor];
                                              self.mistake = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

}

-(void)updateNewProfileToCoreData{
    NSDictionary *newDoctor = [self.responseJSONData objectForKey:@"User"];

    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    [doctor setValue:[newDoctor objectForKey:@"FirstName"]  forKey:@"firstName"];
    [doctor setValue:[newDoctor objectForKey:@"LastName"]  forKey:@"lastName"];
    [doctor setValue:[NSString stringWithFormat:@"%@",[newDoctor objectForKey:@"Birthday"]] forKey:@"birthday"];
    [doctor setValue:[newDoctor objectForKey:@"Phone"]  forKey:@"phone"];
    [doctor setValue:[NSString stringWithFormat:@"%@",[newDoctor objectForKey:@"Gender"]] forKey:@"gender"];
    [doctor setValue:[newDoctor objectForKey:@"Address"]  forKey:@"address"];
    [doctor setValue:[newDoctor objectForKey:@"Password"]  forKey:@"password"];
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        self.mistakeLabel.textColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];
        self.mistakeLabel.text = @"Update successed !";
    }

}
- (IBAction)updateProfile:(id)sender {
    [self.activeField resignFirstResponder];
    self.mistakeLabel.textColor = [UIColor redColor];
    self.mistakeLabel.text = @"";
    //get the current doctor data
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    NSString *oldPassword = [doctor valueForKey:@"password"];
    if (![self.oldPasswordTextField.text isEqual: oldPassword]) {
        self.mistakeLabel.text = @"Your old password is invalid!";
    }else if (![self.brandnewPasswordTextField.text isEqual:self.confirmNewPasswordTextField.text]){
        self.mistakeLabel.text = @"Confirm password invalid!";
    }else{
        [self updateDoctorProfileToAPIWith:[doctor valueForKey:@"email"] and:[doctor valueForKey:@"password"]];
        NSArray *mistakeArray = [self.mistake objectForKey:@"Errors"];
        if (mistakeArray == nil) {
//            self.mistakeLabel.text = @"";
        }else{
            self.mistakeLabel.text = @"";
            //display mistake to user
            for (int index =0; index < mistakeArray.count; index ++) {
                if (index ==0) {
                    self.mistakeLabel.text = [NSString stringWithFormat:@"%@",mistakeArray[index]];
                }else{
                    self.mistakeLabel.text = [NSString stringWithFormat:@"%@, %@",self.mistakeLabel.text,mistakeArray[index]];
                }

            }
        }

    }
    
}
@end
