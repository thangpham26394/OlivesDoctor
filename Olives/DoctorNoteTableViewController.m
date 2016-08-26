//
//  DoctorNoteTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/17/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/diary/filter"
#define APIURLDELETE @"http://olive.azurewebsites.net/api/diary?Id="
#import "DoctorNoteTableViewController.h"
#import "DoctorNoteTableViewCell.h"
#import "AddNewDiaryViewController.h"
#import <CoreData/CoreData.h>

@interface DoctorNoteTableViewController ()
@property(assign,nonatomic) CGFloat noteLabelHeight;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSMutableArray *diaryArray;
@property (strong,nonatomic) NSDictionary *selectedDiary;
@property (assign,nonatomic) BOOL apiDeleted;
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;
@end

@implementation DoctorNoteTableViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)loadDiaryFromCoreDataWhenAPIFail{
    NSMutableArray *diaryArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Diary"];
    NSMutableArray *diaryObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *diary;
    for (int index =0; index<diaryObject.count; index++) {
        //get each patient in coredata
        diary = [diaryObject objectAtIndex:index];
        NSDictionary *diaryDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [diary valueForKey:@"id" ],@"Id",
                                  [diary valueForKey:@"note" ],@"Note",
                                  [diary valueForKey:@"time" ],@"Time",
                                  [diary valueForKey:@"ownerID" ],@"Owner",
                                  [diary valueForKey:@"created" ],@"Created",
                                  [diary valueForKey:@"lastModified" ],@"LastModified",
                                  nil];
        [diaryArrayForFailAPI addObject:diaryDic];

    }
    self.diaryArray = diaryArrayForFailAPI;

}

-(void)saveDiaryToCoreData{
    self.diaryArray = [self.responseJSONData objectForKey:@"Diaries"];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Diary"];
    NSMutableArray *diaryObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *diary;
    //delete previous diary
    if (diaryObject.count >0) {
        for (int index=0; index < diaryObject.count; index++) {
            diary = [diaryObject objectAtIndex:index];
            [context deleteObject:diary];

        }
    }

    // insert new patients that gotten from API
    for (int index = 0; index < self.diaryArray.count; index++) {
        NSDictionary *diaryDic = self.diaryArray[index];

        NSString *diaryID = [diaryDic objectForKey:@"Id"];
        NSString *note = [diaryDic objectForKey:@"Note"];
        NSString *ownerID = [diaryDic objectForKey:@"Owner"];
        NSString *time = [diaryDic objectForKey:@"Time"];
        NSString *createdDate = [diaryDic objectForKey:@"Created"];
        NSString *lastModified = [diaryDic objectForKey:@"LastModified"];


        //create new patient object
        NSManagedObject *newDiary  = [NSEntityDescription insertNewObjectForEntityForName:@"Diary" inManagedObjectContext:context];
        //set value for each attribute of new patient before save to core data
        [newDiary setValue: [NSString stringWithFormat:@"%@", diaryID] forKey:@"id"];
        [newDiary setValue: [NSString stringWithFormat:@"%@", note] forKey:@"note"];
        [newDiary setValue: [NSString stringWithFormat:@"%@", ownerID] forKey:@"ownerID"];
        [newDiary setValue: [NSString stringWithFormat:@"%@", time] forKey:@"time"];
        [newDiary setValue: [NSString stringWithFormat:@"%@", createdDate] forKey:@"created"];
        [newDiary setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"lastModified"];


        NSError *error = nil;
        // Save the object to persistent store
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save Prescription success!");
        }
    }
}


#pragma mark - Connect to API function
-(void)deleteDiaryAPI:(NSString *)diaryID{
    // create url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", APIURLDELETE,diaryID ]];
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
    [urlRequest setHTTPMethod:@"DELETE"];
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
                                              self.apiDeleted = YES;
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

-(void)loadDiaryFromAPI{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Sort" : @"0",
                              @"Target":self.selectedPatientID,
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];

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
                                                  [self saveDiaryToCoreData];
                                              }else{
                                                  [self loadDiaryFromCoreDataWhenAPIFail];
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              //self.patientArray = [self loadPatientFromCoreDataWhenAPIFail];
                                              [self loadDiaryFromCoreDataWhenAPIFail];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}



-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Diary";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}


-(IBAction)addInfo:(id)sender{
    [self performSegueWithIdentifier:@"addNewDiary" sender:self];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    
    self.apiDeleted = NO;

    //start animation
    [self.currentWindow addSubview:self.backgroundView];
    [self.activityIndicator startAnimating];

    //stop animation
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadDiaryFromAPI];
            [self.tableView reloadData];
            [self.activityIndicator stopAnimating];
            [self.backgroundView removeFromSuperview];
        });
    });


}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set up for indicator view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.center = CGPointMake(self.backgroundView .frame.size.width/2, self.backgroundView .frame.size.height/2);
    [self.backgroundView  addSubview:self.activityIndicator];
    self.currentWindow = [UIApplication sharedApplication].keyWindow;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.diaryArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"doctorNoteCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"doctorNoteCell"];

    }
    // Configure the cell...

    NSDictionary *diaryDic = [self.diaryArray objectAtIndex:indexPath.row];
    NSString *note = [diaryDic objectForKey:@"Note"];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setDateFormat:@"MM/dd/yyyy"];

    NSTimeInterval dateTimeInterval = [[diaryDic objectForKey:@"Time"] doubleValue]/1000;
    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:dateTimeInterval];
    NSString *time = [formatter stringFromDate:timeDate];

    cell.textLabel.text = time;
    cell.detailTextLabel.text =note;

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;

    self.noteLabelHeight = [note boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 40, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}
                                              context:nil].size.height;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedDiary = self.diaryArray[indexPath.row];
    [self performSegueWithIdentifier:@"updateDiary" sender:self];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.noteLabelHeight + 50;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //check if selected category can delete or not < only blank category with no medical record related to selected patient can be deleted >

        [self showAlertViewWhenDeleteDiary:indexPath];
    }
}


-(void)showAlertCannotDelete{
    UIAlertController* alert  = [UIAlertController alertControllerWithTitle:@"We are sorry"
                                                                    message:@"Server is temporary not response!"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                     }];

    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showAlertViewWhenDeleteDiary:(NSIndexPath *)indexPath{
    UIAlertController* alert  = [UIAlertController alertControllerWithTitle:@"Are you sure"
                                                    message:@"This diary note will be deleted"
                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //sent request to API here
                                                             NSLog(@"OK Action!");

                                                             NSDictionary *deleteDiary = [self.diaryArray objectAtIndex:indexPath.row];

                                                             //start animation
                                                             [self.currentWindow addSubview:self.backgroundView];
                                                             [self.activityIndicator startAnimating];


                                                             
                                                             //stop animation
                                                             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     //call api to delete in server
                                                                     [self deleteDiaryAPI:[deleteDiary objectForKey:@"Id"]];
                                                                     if (self.apiDeleted) {
                                                                         //delete in category array
                                                                         [self.diaryArray removeObjectAtIndex:indexPath.row];
                                                                         //delete in tableview
                                                                         [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                                                     }else{
                                                                         [self showAlertCannotDelete];
                                                                     }
                                                                     [self.activityIndicator stopAnimating];
                                                                     [self.backgroundView removeFromSuperview];
                                                                 });
                                                             });



                                                         }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * action) {
                                                                 NSLog(@"cancel Action!");
                                                             }];


    [alert addAction:OKAction];
    [alert addAction:cancelAction];

    
    [self presentViewController:alert animated:YES completion:nil];
}


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

    if ([[segue identifier] isEqualToString:@"updateDiary"])
    {
        AddNewDiaryViewController * addNewDiaryViewcontroller = [segue destinationViewController];
        addNewDiaryViewcontroller.selectedDiary = self.selectedDiary;
        addNewDiaryViewcontroller.selectedPatientID = self.selectedPatientID;
        
    }

    if ([[segue identifier] isEqualToString:@"addNewDiary"])
    {
        AddNewDiaryViewController * addNewDiaryViewcontroller = [segue destinationViewController];
        addNewDiaryViewcontroller.selectedPatientID = self.selectedPatientID;

    }
}


@end
