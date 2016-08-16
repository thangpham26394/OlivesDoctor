//
//  PatientsTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 5/26/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/patient/filter"
#import "PatientsTableViewController.h"
#import "SWRevealViewController.h"
#import "PatientTableViewCell.h"
#import "TimePickerViewController.h"
#import "PatientDetailsViewController.h"
#import "MedicalRecordTableViewController.h"
#import "PrescriptionViewController.h"
#import "MoreInfoTableViewController.h"
#import "DoctorNoteTableViewController.h"

#import <CoreData/CoreData.h>
@interface PatientsTableViewController ()
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (strong,nonatomic) NSArray *patientArray;
@property (assign,nonatomic) BOOL isAddNewAppointment;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property(assign,nonatomic) BOOL connectToAPISuccess;
@property(strong,nonatomic) NSDictionary *selectedPatient;
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *manageBarButton;


-(IBAction)cancel:(id)sender;
@end

@implementation PatientsTableViewController

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

-(void)loadPatienttDataFromAPI{

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
                                                  [self savePatientToCoreData];
                                                  self.connectToAPISuccess =YES;
                                              }else{
                                                  self.patientArray = [self loadPatientFromCoreDataWhenAPIFail];
                                                  self.connectToAPISuccess =NO;
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              self.patientArray = [self loadPatientFromCoreDataWhenAPIFail];
                                              self.connectToAPISuccess = NO;
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];

    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

}

-(void)savePatientToCoreData{
    self.patientArray = [self.responseJSONData objectForKey:@"Patients"];
    //delete all the current patients in coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
    NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *patient;
    if (patientObject.count >0) {

        for (int index=0; index < patientObject.count; index++) {
            patient = [patientObject objectAtIndex:index];
            [context deleteObject:patient];
        }
    }

    // insert new patients that gotten from API
    for (int index = 0; index < self.patientArray.count; index++) {
        NSDictionary *patient = self.patientArray[index];
        NSString *patientID = [patient objectForKey:@"Id"];
        NSString *firstName = [patient objectForKey:@"FirstName"];
        NSString *lastName = [patient objectForKey:@"LastName"];
        NSString *birthday = [patient objectForKey:@"Birthday"];
        NSString *phone = [patient objectForKey:@"Phone"];
        NSString *photo = [patient objectForKey:@"Photo"];
        NSString *address = [patient objectForKey:@"Address"];
        NSString *email = [patient objectForKey:@"Email"];
        NSString *weight = [patient objectForKey:@"Weight"];
        NSString *height = [patient objectForKey:@"Height"];

        //create new patient object
        NSManagedObject *newPatient  = [NSEntityDescription insertNewObjectForEntityForName:@"PatientInfo" inManagedObjectContext:context];
        //set value for each attribute of new patient before save to core data
        [newPatient setValue: [NSString stringWithFormat:@"%@", patientID] forKey:@"patientId"];
        [newPatient setValue:firstName forKey:@"firstName"];
        [newPatient setValue:lastName forKey:@"lastName"];
        [newPatient setValue: [NSString stringWithFormat:@"%@", birthday] forKey:@"birthday"];
        [newPatient setValue: [NSString stringWithFormat:@"%@", phone] forKey:@"phone"];
        //get avatar from receive url
        NSData *patientPhotoData;
        if ((id)photo != [NSNull null])  {
            NSURL *url = [NSURL URLWithString:photo];
            patientPhotoData = [NSData dataWithContentsOfURL:url];
        }else{
            patientPhotoData = UIImagePNGRepresentation([UIImage imageNamed:@"nullAvatar"]);
        }


        [newPatient setValue:patientPhotoData  forKey:@"photo"];
        [newPatient setValue: [NSString stringWithFormat:@"%@", address] forKey:@"address"];
        [newPatient setValue: [NSString stringWithFormat:@"%@", email] forKey:@"email"];
        [newPatient setValue: [NSString stringWithFormat:@"%@", weight] forKey:@"weight"];
        [newPatient setValue: [NSString stringWithFormat:@"%@", height] forKey:@"height"];
        NSError *error = nil;
        // Save the object to persistent store
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save Patient success!");
        }
    }
}

-(NSArray *)loadPatientFromCoreDataWhenAPIFail{

    NSMutableArray *patientArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
    NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *patient;
    for (int index =0; index<patientObject.count; index++) {
        //get each patient in coredata
        patient = [patientObject objectAtIndex:index];
        NSDictionary *patientDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [patient valueForKey:@"patientId" ],@"Id",
                                    [patient valueForKey:@"firstName" ],@"FirstName",
                                    [patient valueForKey:@"lastName" ],@"LastName",
                                    [patient valueForKey:@"birthday" ],@"Birthday",
                                    [patient valueForKey:@"phone" ],@"Phone",
                                    [patient valueForKey:@"photo" ],@"Photo",
                                    [patient valueForKey:@"address" ],@"Address",
                                    [patient valueForKey:@"email" ],@"Email",
                                    [patient valueForKey:@"weight" ],@"Weight",
                                    [patient valueForKey:@"height" ],@"Height",
                                    nil];
        [patientArrayForFailAPI addObject:patientDic];
    }

    return (NSArray*)patientArrayForFailAPI;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.patientArray = [[NSArray alloc]init];
    self.tableView.multipleTouchEnabled = NO;
    self.tableView.userInteractionEnabled = YES;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.backgroundView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];

    //setup indicator view
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = CGPointMake(self.backgroundView .frame.size.width/2, self.backgroundView .frame.size.height/2);
    [self.backgroundView  addSubview:self.activityIndicator];
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self.backgroundView];
    [currentWindow bringSubviewToFront:self.backgroundView];

    [self.activityIndicator startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadPatienttDataFromAPI];
            [self.tableView reloadData];
            [self.activityIndicator stopAnimating];
            [self.backgroundView removeFromSuperview];
        });
    });


}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //call API to get Patient data

    self.isAddNewAppointment = NO;
    //setup barbutton
    UIBarButtonItem *leftBarButton ;

    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setShowsVerticalScrollIndicator:NO];

    //back ground for tableview view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menuscreen.jpg"]];
    self.tableView.backgroundView = imageView;

    [self.manageBarButton setEnabled:NO];
    [self.manageBarButton setTintColor: [UIColor clearColor]];

    //set up menu button if not isAppointmentViewDetailPatient
    if ([self.isAppointmentViewDetailPatient  isEqual: @""] || self.isAppointmentViewDetailPatient == nil) {

            [self.manageBarButton setEnabled:YES];
            [self.manageBarButton setTintColor:nil];

            SWRevealViewController *revealViewController = self.revealViewController;

            if (revealViewController) {
                leftBarButton = [[UIBarButtonItem alloc]
                                 initWithImage:[UIImage imageNamed:@"menu.png"]
                                 style:UIBarButtonItemStylePlain
                                 target:self.revealViewController
                                 action:@selector(revealToggle:)];
                self.navigationItem.leftBarButtonItem = leftBarButton;
                [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
            }

    }else{
        // when user choose add new appointment
        self.isAddNewAppointment = YES;
        leftBarButton = [[UIBarButtonItem alloc]
                         initWithTitle:@"Cancel"
                         style:UIBarButtonItemStylePlain
                         target:self
                         action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = leftBarButton;
    }

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)cancel:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.patientArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"patientCell" forIndexPath:indexPath];
    cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@",[self.patientArray[indexPath.row] objectForKey:@"FirstName"],[self.patientArray[indexPath.row] objectForKey:@"LastName"]];
    cell.phoneLabel.text = [NSString stringWithFormat:@"Phone:%@",[self.patientArray[indexPath.row] objectForKey:@"Phone"]];
    cell.address.text = [NSString stringWithFormat:@"Address:%@",[self.patientArray[indexPath.row] objectForKey:@"Address"]];
    cell.emailLabel.text  = [NSString stringWithFormat:@"Email:%@",[self.patientArray[indexPath.row] objectForKey:@"Email"]];

    NSData *data;
    if (self.connectToAPISuccess) {
        NSString * photo = [self.patientArray[indexPath.row] objectForKey:@"Photo"];
//        NSURL *url = [NSURL URLWithString:[self.patientArray[indexPath.row] objectForKey:@"Photo"]];
//        data  = [NSData dataWithContentsOfURL:url];


        if ((id)photo != [NSNull null])  {
            NSURL *url = [NSURL URLWithString:photo];
            data = [NSData dataWithContentsOfURL:url];
        }else{
            data = UIImagePNGRepresentation([UIImage imageNamed:@"nullAvatar"]);
        }

    }else{
        data = [self.patientArray[indexPath.row] objectForKey:@"Photo"];
    }
    UIImage *img = [[UIImage alloc] initWithData:data];
    cell.avatar.image = img;

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected

        self.selectedPatient = self.patientArray[indexPath.row];
        if (!self.isAddNewAppointment) {
            // if the view current state is not for add new appointment
            [self performSegueWithIdentifier:@"showDetailPatient" sender:self];
        }else{
            [self performSegueWithIdentifier:@"unwindToTimePicker" sender:self];
        }



    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView setUserInteractionEnabled:NO];
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"showDetailPatient"])
    {
        UITabBarController *tabBar = [segue destinationViewController];

        PatientDetailsViewController * patientDetail = [tabBar.viewControllers objectAtIndex:1];
        MedicalRecordTableViewController *medicalRecord = [tabBar.viewControllers objectAtIndex:2];
        PrescriptionViewController *prescription = [tabBar.viewControllers objectAtIndex:3];
        MoreInfoTableViewController *moreInfoTableView = [tabBar.viewControllers objectAtIndex:4];
        DoctorNoteTableViewController *diaryView = [tabBar.viewControllers objectAtIndex:0];
        patientDetail.selectedPatientID = [NSString stringWithFormat:@"%@",[self.selectedPatient objectForKey:@"Id"]];
        medicalRecord.selectedPatientID= [NSString stringWithFormat:@"%@",[self.selectedPatient objectForKey:@"Id"]];
        prescription.selectedPatientID = [NSString stringWithFormat:@"%@",[self.selectedPatient objectForKey:@"Id"]];
        moreInfoTableView.selectedPatientID = [NSString stringWithFormat:@"%@",[self.selectedPatient objectForKey:@"Id"]];
        diaryView.selectedPatientID = [NSString stringWithFormat:@"%@",[self.selectedPatient objectForKey:@"Id"]];
        tabBar.selectedIndex = 1;
    }

    if ([[segue identifier] isEqualToString:@"unwindToTimePicker"])
    {
        TimePickerViewController *timePicker = [segue destinationViewController];
       timePicker.selectedPatient = self.selectedPatient;
    }


    

}


@end
