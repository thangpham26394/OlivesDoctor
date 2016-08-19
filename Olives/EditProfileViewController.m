//
//  EditProfileViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/22/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/doctor"
#define APIURLUPLOAD @"http://olive.azurewebsites.net/api/account/avatar"
#define ACCEPTLIMITSIZE 2000
#import "EditProfileViewController.h"
#import "SWRevealViewController.h"
#import "ChangePasswordViewController.h"
#import <CoreData/CoreData.h>
@interface EditProfileViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIDatePicker *birthdayDateTime;

//edit informations
@property (weak, nonatomic) UITextField *activeField;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;




@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSegment;
@property (weak, nonatomic) IBOutlet UIView *genderBackground;
@property (weak, nonatomic) IBOutlet UILabel *mistakeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (strong,nonatomic) NSDictionary *responseJSONData ;
@property (strong,nonatomic) NSDictionary *responseImageData ;
@property (strong,nonatomic) NSDictionary *mistake;

@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;

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

#pragma mark view controller
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scrollView.bounces = NO;
    [self setupGestureRecognizer];
    self.navigationController.navigationBar.translucent = NO;
    self.avatar.layer.cornerRadius = self.avatar.frame.size.width / 2;
    self.avatar.clipsToBounds = YES;
    self.avatar.layer.borderWidth = 1.0f;
    self.avatar.layer.borderColor = [UIColor whiteColor].CGColor;
    self.avatar.userInteractionEnabled = YES;
    [self setupChangeAvatarGestureRecognizer];
    //Set up for slide view
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.menuButton setTarget:self.revealViewController];
        [self.menuButton setAction:@selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    self.contentViewHeight.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;

    [self.saveButton.layer setCornerRadius:5.0f];
    self.saveButton.backgroundColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];

    self.genderBackground.layer.cornerRadius = 5.0f;
    self.genderSegment.tintColor = [UIColor colorWithRed:0/255.0 green:150/255.0 blue:136/255.0 alpha:1.0];

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
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
    //convert date to system date time
    NSDate *birthdaySystemDate = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:birthdayUNIXDate]];
    // Extract the day number (14)
    self.birthdayDateTime.date = birthdaySystemDate;
    self.phoneTextField.text = [doctor valueForKey:@"phone"];
    NSString *gender = [doctor valueForKey:@"gender"];
    if ([gender  isEqual:@"0"]) {
        self.genderSegment.selectedSegmentIndex = 0;
    }else{
        self.genderSegment.selectedSegmentIndex = 1;
    }
    self.addressTextField.text = [doctor valueForKey:@"address"];

    //set up for indicator view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(screenWidth/2-20,screenHeight/2-20 , 40, 40)];
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

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    self.mistakeLabel.text = @"";
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
-(void) setupGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    //tapGesture.cancelsTouchesInView = NO;
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self.activeField resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)unwindToEditProfiler:(UIStoryboardSegue *)unwindSegue
{
//    UIViewController* sourceViewController = unwindSegue.sourceViewController;
//
//    if ([sourceViewController isKindOfClass:[ChangePasswordViewController class]])
//    {
//
//    }

}
#pragma mark - Connect to API function

//resize image func
- (UIImage *)compressForUpload:(UIImage *)original scale:(CGFloat)scale
{
    // Calculate new size given scale factor.
    CGSize originalSize = original.size;
    CGSize newSize = CGSizeMake(originalSize.width * scale, originalSize.height * scale);

    // Scale the original image to match the new size.
    UIGraphicsBeginImageContext(newSize);
    [original drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage* compressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return compressedImage;
}
//upload prescription image
-(void)uploadDoctorImageToAPI:(UIImage *)pickedImage{
    // create url
    NSURL *url = [NSURL URLWithString:APIURLUPLOAD];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];

    NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
    //setup header and body for request
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];

    //set up content type for request <content both params and image data>
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
    [urlRequest setValue:contentType forHTTPHeaderField: @"Content-Type"];



    // config body
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"MedicalRecord\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

    [body appendData:[[NSString stringWithFormat:@"%@\r\n",@""] dataUsingEncoding:NSUTF8StringEncoding]];


    // add image data
    NSData *imgData = UIImagePNGRepresentation(pickedImage);
    NSLog(@"before-------------%lu",imgData.length /1024);

    UIImage *resizedImage = pickedImage;
    while (imgData.length/1024 > ACCEPTLIMITSIZE) {

        resizedImage = [self compressForUpload:resizedImage scale:0.9];
        imgData = UIImagePNGRepresentation(resizedImage);
    }


    NSLog(@"after-------------%lu",imgData.length /1024);


    //create a name for image with the current time in milisec
    NSDateFormatter *dateFormaterToUTC = [[NSDateFormatter alloc] init];
    dateFormaterToUTC.timeStyle = NSDateFormatterNoStyle;
    dateFormaterToUTC.dateFormat = @"MM/dd/yyyy HH:mm:ss:SSS";


    if (imgData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"Avatar\"; filename=\"%@\"\r\n",[dateFormaterToUTC stringFromDate:[NSDate date]]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imgData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];

    // setting the body of the post to the reqeust
    [urlRequest setHTTPBody:body];



    //    [urlRequest setHTTPBody:jsondata];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);

    NSURLSessionTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                  {
                                      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                      if((long)[httpResponse statusCode] == 200  && error ==nil)
                                      {
                                          NSError *parsJSONError = nil;
                                          self.responseImageData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                          if (self.responseImageData != nil) {
                                              [self saveImageToCoreData];

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



-(void)updateDoctorProfileToAPIWith:(NSString*)email and :(NSString*)password forDocTor:(NSString*)doctorID{
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



    // dateformater to convert to UTC time zone
    NSDateFormatter *dateFormaterToUTC = [[NSDateFormatter alloc] init];
    dateFormaterToUTC.timeStyle = NSDateFormatterNoStyle;
    dateFormaterToUTC.dateFormat = @"MM/dd/yyyy HH:mm:ss";
    [dateFormaterToUTC setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSDate *userInputDate = [dateFormaterToUTC dateFromString:[dateFormaterToUTC stringFromDate:self.birthdayDateTime.date]];
    NSTimeInterval birthdayUNIXTime = [userInputDate timeIntervalSince1970];



    //create JSON data to post to API
    NSString *doctorPassword;
    if (self.doctorNewPassword != nil && ![self.doctorNewPassword isEqual:@""]) {
        doctorPassword = self.doctorNewPassword;
    }else{
        doctorPassword = password;
    }
    NSDictionary *account = @{
                              @"FirstName" :  self.firstNameTextField.text,
                              @"LastName" :self.lastNameTextField.text,
                              @"Birthday" : [NSString stringWithFormat:@"%f",birthdayUNIXTime *1000] ,
                              @"Phone" :self.phoneTextField.text,
                              @"Gender" :  [NSString stringWithFormat:@"%ld",(long)self.genderSegment.selectedSegmentIndex],
                              @"Address" :self.addressTextField.text,
                              @"Password" :  doctorPassword
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
                                                  self.mistake = nil;
                                                  [self updateNewProfileToCoreData];
                                              }else{

                                              }
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{

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

-(void)saveImageToCoreData{
    NSDictionary *newDoctor = [self.responseImageData objectForKey:@"User"];
    NSString *photoURL = [newDoctor objectForKey:@"Photo"];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    //get avatar from receive url
    NSURL *url = [NSURL URLWithString:photoURL];
    NSData *doctorPhotoData = [NSData dataWithContentsOfURL:url];
    [doctor setValue:doctorPhotoData  forKey:@"photoURL"];

    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save success!");

        dispatch_async(dispatch_get_main_queue(), ^{
            self.avatar.image = [UIImage imageWithData:doctorPhotoData];
        });
    }

}

-(void)updateNewProfileToCoreData{
    NSDictionary *newDoctor = [self.responseJSONData objectForKey:@"Doctor"];


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
        [self showDoneAlertView];
    }

}

-(void)showDoneAlertView{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Done"
                                                                   message:@"New info have been updated!"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {}];
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
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

    [self updateDoctorProfileToAPIWith:[doctor valueForKey:@"email"] and:[doctor valueForKey:@"password"] forDocTor:[doctor valueForKey:@"doctorID"]];
    NSArray *mistakeArray = [self.mistake objectForKey:@"Errors"];
    if (mistakeArray != nil) {
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [picker dismissViewControllerAnimated:YES completion:^{
        //start animation
        [self.currentWindow addSubview:self.backgroundView];
        [self.activityIndicator startAnimating];
        self.view.userInteractionEnabled = NO;


        //stop animation
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                //get the newest info of current doctor
                [self uploadDoctorImageToAPI:image];
                [self.activityIndicator stopAnimating];
                [self.backgroundView removeFromSuperview];
                self.view.userInteractionEnabled = YES;
            });
        });
        
    }];
//    [self uploadDoctorImageToAPI:image];
}




-(void) setupChangeAvatarGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleChangeAvatarTapGesture:)];
    //tapGesture.cancelsTouchesInView = NO;
    [self.avatar addGestureRecognizer:tapGesture];
}

- (void)handleChangeAvatarTapGesture:(UIPanGestureRecognizer *)recognizer{
    UIImagePickerController *myImagePicker = [[UIImagePickerController alloc] init];
    myImagePicker.delegate = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select Image..."
                                                                             message:@"What would you like to open?"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];



    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             myImagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;

                                                             [self presentViewController:myImagePicker animated:YES completion:nil];
                                                         }];
    UIAlertAction *libraryAction = [UIAlertAction actionWithTitle:@"Library"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              myImagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

                                                              [self presentViewController:myImagePicker animated:YES completion:nil];
                                                          }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

    [alertController addAction:cameraAction];
    [alertController addAction:libraryAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];

}
@end
