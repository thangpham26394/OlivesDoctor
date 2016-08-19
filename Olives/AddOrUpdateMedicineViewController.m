//
//  AddOrUpdateMedicineViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/6/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURLEDIT @"http://olive.azurewebsites.net/api/medical/prescription?id="
#import "AddOrUpdateMedicineViewController.h"
#import <CoreData/CoreData.h>



@interface AddOrUpdateMedicineViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *quantityTextField;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;
@property (weak, nonatomic) IBOutlet UITextField *unitTextField;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;

- (IBAction)saveButtonAction:(id)sender;
@property (weak, nonatomic) UITextView *activeView;
@property (weak, nonatomic) UITextField *activeField;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSString *prescriptionID;
@property (strong,nonatomic) NSString *medicineString;
@property(strong,nonatomic) NSMutableDictionary *medicinedic;
@end

@implementation AddOrUpdateMedicineViewController

- (IBAction)textViewDidBeginEditing:(UITextView *)sender
{
    self.activeView = sender;
}

- (IBAction)textViewDidEndEditing:(UITextView *)sender
{
    self.activeView = nil;
}
- (IBAction)textFieldDidBeginEditing:(UITextField *)sender
{
    self.activeField = sender;
}

- (IBAction)textFieldDidEndEditing:(UITextField *)sender
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
        if (self.activeView ==nil) {
            [self.scrollView scrollRectToVisible:self.activeField.frame animated:YES];
        }else{
            [self.scrollView scrollRectToVisible:self.activeView.frame animated:YES];
        }

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
    if (self.activeView ==nil) {
        [self.activeField resignFirstResponder];
    }else{
        [self.activeView resignFirstResponder];
    }
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
    self.noteTextView.layer.cornerRadius = 5.0f;
    self.prescriptionID = [self.selectedPrescription objectForKey:@"Id"];
    self.medicineString = [self.selectedPrescription objectForKey:@"Medicine"];
    if ((id)self.medicineString == [NSNull null]) {
        self.medicineString =@"";
    }
    NSError *jsonError;
    NSData *objectData = [self.medicineString dataUsingEncoding:NSUTF8StringEncoding];
    self.medicinedic = [NSJSONSerialization JSONObjectWithData:objectData
                                                       options:NSJSONReadingMutableContainers
                                                         error:&jsonError];


    if (self.selectedMedicine != nil) {
        NSString *name = [[self.selectedMedicine allKeys] objectAtIndex:0];
        self.nameTextField.text = name;
        NSDictionary *value = [self.selectedMedicine objectForKey:name];
        self.quantityTextField.text = [NSString stringWithFormat:@"%@",[value objectForKey:@"Quantity"]];
        self.unitTextField.text = [NSString stringWithFormat:@"%@",[value objectForKey:@"Unit"]];
        self.noteTextView.text = [NSString stringWithFormat:@"%@",[value objectForKey:@"Note"]];
    }
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

    //create new medicine dic with added info
    NSString *key = self.nameTextField.text;
    NSDictionary *value = [NSDictionary dictionaryWithObjectsAndKeys:
                           self.quantityTextField.text,@"Quantity",
                           self.unitTextField.text,@"Unit",
                           self.noteTextView.text,@"Note"
                           , nil];
    if (self.medicinedic ==nil) {
        self.medicinedic = [[NSMutableDictionary alloc]init];
    }
    if (self.selectedMedicine != nil) {
        [self.medicinedic removeObjectForKey:[[self.selectedMedicine allKeys] objectAtIndex:0]];
    }


    [self.medicinedic setObject:value forKey:key];

    NSDictionary *account = @{
                              @"Medicines" :  self.medicinedic,
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

        for (int index=0; index < prescriptionObject.count; index++) {
            prescription = [prescriptionObject objectAtIndex:index];
            //find out the prescription in coredata that have same id with selected prescription to update
            if ([[prescription valueForKey:@"prescriptionID"] isEqual:[NSString stringWithFormat:@"%@",[self.selectedPrescription objectForKey:@"Id"]]]) {

                NSError * err;
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:self.medicinedic options:0 error:&err];
                NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [prescription setValue: myString forKey:@"medicine"];
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


- (IBAction)saveButtonAction:(id)sender {
    [self editwPrescriptionAPI];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
