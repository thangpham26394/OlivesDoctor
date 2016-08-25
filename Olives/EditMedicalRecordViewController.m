//
//  EditMedicalRecordViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/13/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURLEDIT @"http://olive.azurewebsites.net/api/medical/record?Id="
#import "EditMedicalRecordViewController.h"
#import "PickNewMedicalRecordViewController.h"
#import <CoreData/CoreData.h>

@interface EditMedicalRecordViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *dateTimePicker;
@property (weak, nonatomic) IBOutlet UIView *selectCategoryView;

@property (weak, nonatomic) IBOutlet UILabel *medicalCategoryName;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;


- (IBAction)saveButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSDictionary *selectedCategory;
@end

@implementation EditMedicalRecordViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)saveMedicalRecordToCoreData{
    //get the medical record of specific patient which data was returned from API
    NSDictionary *newMedicalRecordDic = [self.responseJSONData objectForKey:@"MedicalRecord"];

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
    NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalRecord;


    for (int index=0; index < medicalRecordObject.count; index++) {
        medicalRecord = [medicalRecordObject objectAtIndex:index];
        if ([[medicalRecord valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",[newMedicalRecordDic objectForKey:@"Id"]]]) {

            [context deleteObject:medicalRecord];// only delete object that have save id with new updated medical record
            
        }
        
    }

    NSString *medicalRecordID = [newMedicalRecordDic objectForKey:@"Id"];
    NSString *owner = [[newMedicalRecordDic objectForKey:@"Owner"] objectForKey:@"Id"];
    NSString *creator = [[newMedicalRecordDic objectForKey:@"Creator"] objectForKey:@"Id"];
    NSString *categoryID = [self.selectedCategory objectForKey:@"Id"];
    NSString *info = [newMedicalRecordDic objectForKey:@"Info"];
    NSString *time = [newMedicalRecordDic objectForKey:@"Time"];
    NSString *createdDate = [newMedicalRecordDic objectForKey:@"Created"];
    NSString *lastModified = [newMedicalRecordDic objectForKey:@"LastModified"];
    NSString *name = [newMedicalRecordDic objectForKey:@"Name"];



    //create new medical record object
    NSManagedObject *newMedicalRecord = [NSEntityDescription insertNewObjectForEntityForName:@"MedicalRecord" inManagedObjectContext:context];
    //set value for each attribute of new patient before save to core data
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", medicalRecordID] forKey:@"medicalRecordID"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", owner] forKey:@"ownerID"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", creator] forKey:@"creatorID"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", categoryID] forKey:@"categoryID"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", info] forKey:@"info"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", time] forKey:@"time"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", createdDate] forKey:@"createdDate"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", name] forKey:@"name"];
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"LastModified"];

    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save MedicalRecord success!");
    }

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
    if (!CGRectContainsPoint(aRect, self.nameTextField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.nameTextField.frame animated:YES];
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
    [self.nameTextField resignFirstResponder];
}





#pragma mark - Connect to API function

-(void)editMedicalRecordAPI{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURLEDIT,[self.medicalRecordDic objectForKey:@"Id"]]];
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

    NSDate *convertdateTime = [formatter dateFromString:[formatter stringFromDate:self.dateTimePicker.date]];
    NSTimeInterval dateTimeUNIX = [convertdateTime timeIntervalSince1970];

    NSDictionary *account = @{
                              @"Time":[NSString stringWithFormat:@"%f",dateTimeUNIX*1000],
                              @"Name":self.nameTextField.text,
                              @"Category":[self.selectedCategory objectForKey:@"Id"],
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
                                                  [self saveMedicalRecordToCoreData];
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self showSucces];
                                                  });
                                              }else{
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self showAlertError:@"Cannot connect to server"];
                                                  });
                                              }

                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSError *parsJSONError = nil;
                                              if (data ==nil) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self showAlertError:@"Cannot connect to server"];
                                                  });

                                                  dispatch_semaphore_signal(sem);
                                                  return;
                                              }else{
                                                  NSDictionary *errorDic = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                                  NSArray *errorArray = [errorDic objectForKey:@"Errors"];
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      if (errorArray != nil) {
                                                          [self showAlertError:[errorArray objectAtIndex:0]];
                                                      }else{
                                                          [self showAlertError:@"Edit failed!"];
                                                      }

                                                  });

                                                  dispatch_semaphore_signal(sem);
                                                  return;
                                              }

                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

//show alert message for error
-(void)showAlertError:(NSString *)errorString{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:errorString
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         [self.navigationController popViewControllerAnimated:YES];
                                                     }];
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
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

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.medicalCategoryName.text = [self.selectedCategory objectForKey:@"Name"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.translucent = NO;
    self.saveButton.backgroundColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];
    [self.saveButton.layer setCornerRadius:5.0f];
    self.contentViewHeight.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;
    self.dateTimePicker.backgroundColor = [UIColor whiteColor];
    self.dateTimePicker.layer.cornerRadius = 5.0f;
    self.dateTimePicker.layer.masksToBounds = YES;

    self.selectCategoryView.layer.cornerRadius = 5.0f;

    self.nameTextField.text = [self.medicalRecordDic objectForKey:@"Name"];
    self.selectedCategory = [self.medicalRecordDic objectForKey:@"Category"];

    //set up dateformater to local time
    NSDateFormatter * dateFormatToLocal = [[NSDateFormatter alloc] init];
    [dateFormatToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatToLocal setLocale:[NSLocale systemLocale]];
    [dateFormatToLocal setDateFormat:@"MM/dd/yyyy HH:mm:ss:SSS"];


    NSDate *dateTime = [NSDate dateWithTimeIntervalSince1970:[[self.medicalRecordDic objectForKey:@"Time"] doubleValue] /1000];

    dateTime = [dateFormatToLocal dateFromString:[dateFormatToLocal stringFromDate:dateTime]];

    self.dateTimePicker.date = dateTime;

    [self setupMessageGestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setupMessageGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMessageTapGesture:)];
    //tapGesture.cancelsTouchesInView = NO;
    [self.selectCategoryView addGestureRecognizer:tapGesture];
}

- (void)handleMessageTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self performSegueWithIdentifier:@"selectMedicalCategory" sender:self];
}



-(void)showSucces{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Done"
                                                                   message:@"Your medical record has been updated successfully!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                          [self.navigationController popViewControllerAnimated:YES];
                                                     }];
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"selectMedicalCategory"])
    {
        PickNewMedicalRecordViewController *medicalRecordCategory = [segue destinationViewController];
        medicalRecordCategory.isEditMedicalRecord = YES;

    }
    
}
- (IBAction)unwindChoseOtherMedicalRecordViewController:(UIStoryboardSegue *)unwindSegue
{
    PickNewMedicalRecordViewController* sourceViewController = unwindSegue.sourceViewController;
    self.selectedCategory = sourceViewController.selectedCategory;
}

- (IBAction)saveButtonAction:(id)sender {
    [self editMedicalRecordAPI];
    
}
@end
