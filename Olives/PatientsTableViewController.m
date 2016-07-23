//
//  PatientsTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 5/26/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/people/filter"
#import "PatientsTableViewController.h"
#import "SWRevealViewController.h"
#import "PatientTableViewCell.h"
#import <CoreData/CoreData.h>
@interface PatientsTableViewController ()
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (strong,nonatomic) NSArray *patientArray;
@property (assign,nonatomic) BOOL isAddNewAppointment;
@property (strong,nonatomic) NSDictionary *responseJSONData ;

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
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self loadPatienttDataFromAPI];
    self.patientArray = [self.responseJSONData objectForKey:@"Users"];
    [self.tableView reloadData];
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

    //set up menu button if not isAppointmentViewDetailPatient
    if ([self.isAppointmentViewDetailPatient  isEqual: @""] || self.isAppointmentViewDetailPatient == nil) {


        SWRevealViewController *revealViewController = self.revealViewController;

        if (revealViewController) {
            leftBarButton = [[UIBarButtonItem alloc]
                             initWithImage:[UIImage imageNamed:@"menu.png"]
                             style:UIBarButtonItemStylePlain
                             target:self.revealViewController
                             action:@selector(revealToggle:)];
            self.navigationItem.leftBarButtonItem = leftBarButton;

//            [self.menuButton setTarget:self.revealViewController];
//            [self.menuButton setAction:@selector(revealToggle:)];
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
    NSURL *url = [NSURL URLWithString:[self.patientArray[indexPath.row] objectForKey:@"Photo"]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *img = [[UIImage alloc] initWithData:data];
    cell.avatar.image = img;
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    if (!self.isAddNewAppointment) {
        // if the view current state is not for add new appointment
        [self performSegueWithIdentifier:@"showDetailPatient" sender:self];
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
        tabBar.selectedIndex = 1;
    }
}


@end
