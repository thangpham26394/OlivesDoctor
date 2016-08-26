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
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator;
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

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.backgroundView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];

    //setup indicator view
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = CGPointMake(self.backgroundView .frame.size.width/2, self.backgroundView .frame.size.height/2);
    [self.backgroundView  addSubview:self.activityIndicator];



    
    
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
    [self deleteDoctorInfoWhenLogout];
    [self stopHubConnection];
    [self registerForKeyboardNotifications];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"loginViewLoaded"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewWillDisappear:(BOOL)animated {

    [self deregisterFromKeyboardNotifications];
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"loginViewLoaded"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

#pragma handle API connection
-(void)loginAPI{
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
                                              if (self.responseJSONData !=nil) {
                                                  if ([ [NSString stringWithFormat:@"%@", [[self.responseJSONData objectForKey:@"User"] objectForKey:@"Role"]] isEqual:@"3"]) {
                                                      self.canLogin = YES;
                                                  }else
                                                  {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self showAlertError:@"Invalid email or password"];
                                                      });
                                                      self.canLogin = NO;
                                                  }

                                              }else{
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self showAlertError:@"Cannot connect to server"];
                                                  });
                                                  self.canLogin = NO;
                                              }

                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              self.canLogin = NO;
                                              NSError *parsJSONError = nil;
                                              if (data ==nil) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Internet Error"
                                                                                                                     message:nil
                                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                                      UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                         style:UIAlertActionStyleDefault
                                                                                                       handler:^(UIAlertAction * action) {}];
                                                      [alert addAction:OKAction];
                                                      [self presentViewController:alert animated:YES completion:nil];
                                                  });

                                                  dispatch_semaphore_signal(sem);
                                                  return;
                                              }
                                              else{
                                                  NSDictionary *errorDic = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                                  NSArray *errorArray = [errorDic objectForKey:@"Errors"];
                                                  //                                              NSLog(@"\n\n\nError = %@",[errorArray objectAtIndex:0]);

                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Invalid email or password"
                                                                                                                     message:[errorArray objectAtIndex:0]
                                                                                                              preferredStyle:UIAlertControllerStyleAlert];

                                                      UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                         style:UIAlertActionStyleDefault
                                                                                                       handler:^(UIAlertAction * action) {}];
                                                      [alert addAction:OKAction];
                                                      [self presentViewController:alert animated:YES completion:nil];
                                                  });
                                                  dispatch_semaphore_signal(sem);
                                                  return;
                                              }
                                          }

                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);


    if (self.canLogin ) {
        //store doctor's data to Coredata
        [self saveDoctorInfoToCoreData:self.responseJSONData];
        //create local noti to open hub connection in appdeledate
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        notification.alertBody = @"OpenHubForAppDoctor";
        notification.alertAction = @"Show me";
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];


        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"loginStatus"];
        [[NSUserDefaults standardUserDefaults] synchronize];


        //perform segue to move to homescreen
        [self performSegueWithIdentifier: @"loginSegue" sender: self];
    }else{
        //        [self setLoginStatusToBeNO];

    }

}

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

-(IBAction)loginButton:(id)sender{
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self.backgroundView];
    [currentWindow bringSubviewToFront:self.backgroundView];
    [self.activityIndicator startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self loginAPI];
            [self.activityIndicator stopAnimating];
            [self.backgroundView removeFromSuperview];
        });
    });

}

-(void)stopHubConnection{
    //create local noti to close hub connection in appdeledate
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    notification.alertBody = @"CloseHubForAppDoctor";
    notification.alertAction = @"Show me";
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

-(void)deleteDoctorInfoWhenLogout{
    NSManagedObjectContext *context = [self managedObjectContext];
    //Check if there is already a doctor account in coredata
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *currentDoctor;
    if (doctorObject.count >0) {
        for (int index =0; index <doctorObject.count; index++) {
            currentDoctor = [doctorObject objectAtIndex:index];
            [context deleteObject:currentDoctor];
        }
    }

    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"delete success!");
    }

}

-(void)saveDoctorInfoToCoreData:(NSDictionary*) jsonData
{
    NSDictionary * doctorInfo = [jsonData valueForKey:@"User"];

    NSString * doctorID = [doctorInfo objectForKey:@"Id"];
    NSString * doctorEmail = [doctorInfo objectForKey:@"Email"];
    NSString * doctorPassword = self.passwordTextField.text;
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

    NSData *doctorPhotoData;
    if ((id)doctorPhoto != [NSNull null])  {
        NSURL *url = [NSURL URLWithString:doctorPhoto];
        doctorPhotoData = [NSData dataWithContentsOfURL:url];
    }else{
        doctorPhotoData = UIImagePNGRepresentation([UIImage imageNamed:@"nullAvatar"]);
    }


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
