//
//  ViewDetailPatientInfoViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/12/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/patient?Id="
#import "ViewDetailPatientInfoViewController.h"
#import <CoreData/CoreData.h>


@interface ViewDetailPatientInfoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UITextField *birthdayTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *weightTextField;
@property (weak, nonatomic) IBOutlet UITextField *heightTextField;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;
@property (strong,nonatomic) NSDictionary *responseJSONData ;
@property (weak, nonatomic) IBOutlet UILabel *noteLabel;

@end

@implementation ViewDetailPatientInfoViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

#pragma mark - Handle API connection

-(void)getCurrentPatientAPIWithID:(NSString*)patientID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",APIURL,patientID]];
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
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];



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
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.avatar.layer.cornerRadius = self.avatar.frame.size.width / 2;
    self.avatar.clipsToBounds = YES;
    self.avatar.layer.borderWidth = 1.0f;
    self.avatar.layer.borderColor = [UIColor whiteColor].CGColor;

    [self.noteTextView setEditable:NO];
    self.noteTextView.layer.cornerRadius = 5.0f;
    if (self.currentPatientID != nil) {
        //display info for current patient
        [self getCurrentPatientAPIWithID:self.currentPatientID];
        NSDictionary *currentPatientDic = [self.responseJSONData objectForKey:@"Patient"];
        UIImage *img;
        NSString *imgURL = [currentPatientDic objectForKey:@"Photo"];
        if ((id)imgURL != [NSNull null]) {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgURL]];
            img = [[UIImage alloc] initWithData:data];
        }else{
            img = [UIImage imageNamed:@"nullAvatar"];
        }

        self.avatar.image = img; //set avatar
        self.nameLabel.text = [NSString stringWithFormat:@"%@%@", [currentPatientDic objectForKey:@"FirstName"] ,[currentPatientDic objectForKey:@"LastName"] ];
        NSString *birthdayString = [NSString stringWithFormat:@"%@",[currentPatientDic objectForKey:@"Birthday"] ];
        //convert time interval to NSDate type
        NSDate *birthdayUNIXDate = [NSDate dateWithTimeIntervalSince1970:[birthdayString doubleValue]/1000];
        NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
        [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatterToLocal setDateFormat:@"MM-dd-yyyy"];

        self.birthdayTextField.text = [dateFormatterToLocal stringFromDate:birthdayUNIXDate];
        if ([currentPatientDic objectForKey:@"Phone"] != [NSNull null]) {
            self.phoneTextField.text = [NSString stringWithFormat:@"%@",[currentPatientDic objectForKey:@"Phone"] ];
        }

        if ([currentPatientDic objectForKey:@"Address"] != [NSNull null]) {
            self.addressTextField.text = [NSString stringWithFormat:@"%@",[currentPatientDic objectForKey:@"Address"] ];
        }

        if ([currentPatientDic objectForKey:@"Weight"] != [NSNull null]) {
            self.weightTextField.text = [NSString stringWithFormat:@"%@",[currentPatientDic objectForKey:@"Weight"] ];
        }

        if ([currentPatientDic objectForKey:@"Height"] != [NSNull null]) {
            self.heightTextField.text = [NSString stringWithFormat:@"%@",[currentPatientDic objectForKey:@"Height"] ];
        }
        self.noteTextView.hidden = YES;
        self.noteLabel.hidden = YES;

    }else{
        //display info for pending patient
        NSDictionary *patientDic = [self.selectedPatient objectForKey:@"Source"];

        UIImage *img;
        NSString *imgURL = [patientDic objectForKey:@"Photo"];
        if ((id)imgURL != [NSNull null]) {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgURL]];
            img = [[UIImage alloc] initWithData:data];
        }else{
            img = [UIImage imageNamed:@"nullAvatar"];
        }

        self.avatar.image = img; //set avatar



        self.nameLabel.text = [NSString stringWithFormat:@"%@%@", [patientDic objectForKey:@"FirstName"] ,[patientDic objectForKey:@"LastName"] ];

        NSString *birthdayString = [NSString stringWithFormat:@"%@",[patientDic objectForKey:@"Birthday"] ];
        //convert time interval to NSDate type
        NSDate *birthdayUNIXDate = [NSDate dateWithTimeIntervalSince1970:[birthdayString doubleValue]/1000];
        NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
        [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatterToLocal setDateFormat:@"MM-dd-yyyy"];

        self.birthdayTextField.text = [dateFormatterToLocal stringFromDate:birthdayUNIXDate];
        if ([patientDic objectForKey:@"Phone"] != [NSNull null]) {
            self.phoneTextField.text = [NSString stringWithFormat:@"%@",[patientDic objectForKey:@"Phone"] ];
        }

        if ([patientDic objectForKey:@"Address"] != [NSNull null]) {
            self.addressTextField.text = [NSString stringWithFormat:@"%@",[patientDic objectForKey:@"Address"] ];
        }

        if ([patientDic objectForKey:@"Weight"] != [NSNull null]) {
            self.weightTextField.text = [NSString stringWithFormat:@"%@",[patientDic objectForKey:@"Weight"] ];
        }

        if ([patientDic objectForKey:@"Height"] != [NSNull null]) {
            self.heightTextField.text = [NSString stringWithFormat:@"%@",[patientDic objectForKey:@"Height"] ];
        }

        if ([self.selectedPatient objectForKey:@"Content"] != [NSNull null]) {
            self.noteTextView.text = [NSString stringWithFormat:@"%@", [self.selectedPatient objectForKey:@"Content"]];
        }

    }








    self.birthdayTextField.userInteractionEnabled = NO;
    self.phoneTextField.userInteractionEnabled = NO;
    self.addressTextField.userInteractionEnabled = NO;
    self.weightTextField.userInteractionEnabled = NO;
    self.heightTextField.userInteractionEnabled = NO;
    self.noteTextView.userInteractionEnabled = NO;
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
