//
//  LoginViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 6/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/account/login"


#import "LoginViewController.h"
#import <CoreData/CoreData.h>

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) UITextField *activeField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (strong,nonatomic) NSDictionary *responseJSONData ;
@property BOOL canLogin;
-(IBAction)loginButton:(id)sender;

@property (strong,nonatomic) NSData * returnData;
@end

@implementation LoginViewController

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

    //Set login status for current account to be NO
    //This case is happen after user choose log out from sidebar
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"loginStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    self.canLogin = NO;
    // Set up login Button
    [self.loginButton.layer setCornerRadius:self.loginButton.frame.size.height/2+1];
    self.loginButton.layer.shadowColor = [UIColor colorWithRed:0/255.0 green:150/255.0 blue:150/255.0 alpha:0.5f].CGColor;
    self.loginButton.layer.shadowOffset = CGSizeMake(0.0f, 10.0f);
    self.loginButton.layer.shadowOpacity = 0.5f;
    self.forgotPasswordButton.contentHorizontalAlignment =UIControlContentHorizontalAlignmentRight;
    self.emailTextField.placeholder = @" Email...";
    self.passwordTextField.placeholder = @" Password...";
    [self setupGestureRecognizer];

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
    if (!CGRectContainsPoint(aRect, self.loginButton.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.loginButton.frame animated:YES];
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
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self.activeField resignFirstResponder];
}

-(IBAction)loginButton:(id)sender{
    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Email" :  self.emailTextField.text,
                              @"Password" :self.passwordTextField.text
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];


    // config session
    NSURLSession *defaultSession = [NSURLSession sharedSession];

    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //setup method and body for request
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"text/json" forHTTPHeaderField:@"Content-type"];
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
                                                               self.canLogin = YES;


                                                               //stop waiting after get response from API
                                                               dispatch_semaphore_signal(sem);

                                                           }
                                                           else{
                                                               NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                               NSLog(@"\n\n\nError = %@",text);
                                                               self.canLogin = NO;
                                                               dispatch_semaphore_signal(sem);
                                                               return;
                                                           }
                                                           
                                                       }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);


    if (self.canLogin ) {
        //store doctor's data to Coredata
        [self saveDoctorInfoToCoreData:self.responseJSONData];

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"loginStatus"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        //perform segue to move to homescreen
        [self performSegueWithIdentifier: @"loginSegue" sender: self];
    }else{
//        [self setLoginStatusToBeNO];

    }


}


-(void)saveDoctorInfoToCoreData:(NSDictionary*) jsonData
{
    NSDictionary * doctorInfo = [jsonData valueForKey:@"User"];

    NSString * doctorID = [doctorInfo objectForKey:@"Id"];
    NSString * doctorEmail = [doctorInfo objectForKey:@"Email"];
    NSString * doctorPassword = [doctorInfo objectForKey:@"Password"];
    NSString * doctorFirstName = [doctorInfo objectForKey:@"FirstName"];
    NSString * doctorLastName = [doctorInfo objectForKey:@"LastName"];
    NSString * doctorBirthDay = [doctorInfo objectForKey:@"Birthday"];
    NSString * doctorPhone = [doctorInfo objectForKey:@"Phone"];
    NSString * doctorGender = [doctorInfo objectForKey:@"Gender"];
    NSString * doctorCreatedAccountDay = [doctorInfo objectForKey:@"Created"];
    NSString * doctorStatus = [doctorInfo objectForKey:@"Status"];
    NSString * doctorAddress= [doctorInfo objectForKey:@"Address"];
    NSString * doctorPhoto = [doctorInfo objectForKey:@"Photo"];


    NSManagedObjectContext *context = [self managedObjectContext];
    //Check if there is already a doctor account in coredata
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    // Create a new managed object
    NSManagedObject *newDoctor;
    if (doctorObject.count ==0) {
        newDoctor = [NSEntityDescription insertNewObjectForEntityForName:@"DoctorInfo" inManagedObjectContext:context];
    }else{
        newDoctor = [doctorObject objectAtIndex:0];
    }

    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorID] forKey:@"doctorID"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorEmail] forKey:@"email"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorPassword] forKey:@"password"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorFirstName] forKey:@"firstName"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorLastName] forKey:@"lastName"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorBirthDay] forKey:@"birthday"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorGender] forKey:@"gender"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorPhone] forKey:@"phone"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorCreatedAccountDay] forKey:@"accountCreatedDay"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorStatus] forKey:@"status"];
    [newDoctor setValue: [NSString stringWithFormat:@"%@", doctorAddress] forKey:@"address"];

    //get avatar from receive url
    NSURL *url = [NSURL URLWithString:doctorPhoto];
    NSData *doctorPhotoData = [NSData dataWithContentsOfURL:url];

    [newDoctor setValue:doctorPhotoData  forKey:@"photoURL"];




    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save success!");
    }

}

- (IBAction)unwindToLoginViewController:(UIStoryboardSegue *)unwindSegue
{
    //    UIViewController* sourceViewController = unwindSegue.sourceViewController;
    //
    //    if ([sourceViewController isKindOfClass:[ChangePasswordViewController class]])
    //    {
    //
    //    }
    
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
