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
//    NSDictionary *account = self.totalInfo;
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
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              if (self.isUpdateView) {
                                                  self.totalInfo = self.updateCopy;
                                              }
                                              //create new api no need load from core data when api fail
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
            [medicalRecord setValue:[NSString stringWithFormat:@"%@",self.totalInfo] forKey:@"info"];//only update medical record that selected before

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


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];

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
    }
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

//        self.info = [NSDictionary dictionaryWithObjectsAndKeys:
//                     value,name
//                     , nil];

        
    }
    [self updateNewMedicalRecordDataToAPI];

}


- (IBAction)saveAction:(id)sender {
    if (self.isUpdateView) {
        //edit an exist info string
        [self performSegueWithIdentifier:@"updateInfoUnwind" sender:self];
    }else{
        //add new info string
        [self performSegueWithIdentifier:@"addNewInfoUnwind" sender:self];
    }
}
@end
