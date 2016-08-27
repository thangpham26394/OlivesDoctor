//
//  UpdateDetailInfoMedicalRecordViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/2/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/record?id="
#import "UpdateDetailInfoMedicalRecordViewController.h"
#import "StringStringTableViewCell.h"
#import <CoreData/CoreData.h>


@interface UpdateDetailInfoMedicalRecordViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfContentView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSMutableDictionary *updateCopy;
@property(assign,nonatomic) BOOL isUpdateView;
- (IBAction)saveAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *deleteOrCancalButton;


@end

@implementation UpdateDetailInfoMedicalRecordViewController
#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}


#pragma mark - Connect to API function
-(void)updateNewMedicalRecordDataToAPI{

    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURL,[self.selectedMedicalRecord objectForKey:@"Id"]]];
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

    NSDictionary *account = @{
                              @"Infos" :self.totalInfo,
                              @"Category":[[self.selectedMedicalRecord objectForKey:@"Category"]objectForKey:@"Id"],
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
                                              }else{
                                                  //create new api no need load from core data when api fail
                                                  if (self.isUpdateView) {
                                                      self.totalInfo = self.updateCopy;
                                                  }
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              if (self.isUpdateView) {
                                                  self.totalInfo = self.updateCopy;
                                              }
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

-(void)saveMedicalRecordToCoreData {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
    NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalRecord;

    for (int index=0; index < medicalRecordObject.count; index++) {
        medicalRecord = [medicalRecordObject objectAtIndex:index];
        if ([[medicalRecord valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",[self.selectedMedicalRecord objectForKey:@"Id"]]]) {

            NSError * err;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:self.totalInfo options:0 error:&err];
            NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

            [medicalRecord setValue:[NSString stringWithFormat:@"%@",myString] forKey:@"info"];//only update medical record that selected before

        }

    }

    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save MedicalRecord success!");
        if (!self.isUpdateView) {
            NSString *name = self.textField.text;
            NSString *value = self.textView.text;
            self.info = [NSDictionary dictionaryWithObjectsAndKeys:
                         value,name
                         , nil];
        }

    }
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

    kbRect = [self.view convertRect:kbRect fromView:nil];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if ([self.textView isFirstResponder] ) {
        [self.scrollView scrollRectToVisible:self.textView.frame animated:YES];
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
    [self.textField resignFirstResponder];
    [self.textView resignFirstResponder];
}


- (void)viewWillDisappear:(BOOL)animated {

    [self deregisterFromKeyboardNotifications];
    [super viewWillDisappear:animated];

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self registerForKeyboardNotifications];
    [self setupGestureRecognizerToDisMissKeyBoard];
    if (self.isUpdateView) {
        self.navigationController.topViewController.title=@"Update info";
    }else{
        self.navigationController.topViewController.title=@"Add new info";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.heightOfContentView.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;
    self.isUpdateView = NO;
    NSLog(@"thangthangthang %@",[self.totalInfo objectForKey:self.selectedInfoKey]);
    if (self.selectedInfoKey !=nil) {
        self.isUpdateView = YES;
    }
    if (self.isUpdateView) {
        self.textField.text = self.selectedInfoKey;
        self.textView.text = [self.totalInfo objectForKey:self.selectedInfoKey];
        [self.deleteOrCancalButton setTitle:@"Delete" forState:UIControlStateNormal];
    }
    self.textView.layer.cornerRadius = 5.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    if (self.textField.text.length > 32) {
        [self showAlertError:@"Name can content maximum 32 characters only!"];
        return;
    }
    if (self.textView.text.length >32) {
        [self showAlertError:@"Value can content maximum 32 characters only!"];
        return;
    }

    if ([[segue identifier] isEqualToString:@"addNewInfoUnwind"])
    {
        NSString *name = self.textField.text;
        NSString *value = self.textView.text;
        [self.totalInfo setObject:value forKey:name];
    }

    if ([[segue identifier] isEqualToString:@"updateInfoUnwind"])
    {
        //create info dictionary to send to api
        NSString *name = self.textField.text;
        NSString *value = self.textView.text;
        //create mutable copy of totalinfo
        self.updateCopy = [self.totalInfo mutableCopy];
        [self.totalInfo removeObjectForKey:self.selectedInfoKey];
        [self.totalInfo setObject:value forKey:name];

    }

    if ([[segue identifier] isEqualToString:@"deleteInfoUnwind"])
    {
        //create mutable copy of totalinfo
        self.updateCopy = [self.totalInfo mutableCopy];
        [self.totalInfo removeObjectForKey:self.selectedInfoKey]; //remove info in dictionary
    }



    [self updateNewMedicalRecordDataToAPI];

}


- (IBAction)saveAction:(id)sender {
    if (self.canEdit) {
        //validate name info
        if ([self.textField.text isEqualToString: @""]) {
            [self showAlertError:@"Name can not be empty!"];
            return;
        }
        //validate info
        if ([self.textView.text isEqualToString: @""]) {
            [self showAlertError:@"Result can not be empty!"];
            return;
        }

        if (self.isUpdateView) {
            //edit an exist info string
            [self performSegueWithIdentifier:@"updateInfoUnwind" sender:self];
        }else{
            //add new info string
            [self performSegueWithIdentifier:@"addNewInfoUnwind" sender:self];
        }
    }else{
        [self showAlertError:@"You don't have permission in this medical record"];
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



- (IBAction)deleteAction:(id)sender {
    if (self.isUpdateView) {
        [self showAlertViewWhenDelete];

    }else{
        //add new info string
       [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)showAlertViewWhenDelete{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure"
                                                                   message:@"This info will be deleted"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         //sent request to API here
                                                         NSLog(@"OK Action!");
                                                         [self performSegueWithIdentifier:@"deleteInfoUnwind" sender:self];

                                                     }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             NSLog(@"cancel Action!");
                                                         }];


    [alert addAction:OKAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
