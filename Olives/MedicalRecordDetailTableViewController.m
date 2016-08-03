//
//  MedicalRecordDetailTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/record"
#import "MedicalRecordDetailTableViewController.h"
#import "MedicalNoteTableViewController.h"
#import <CoreData/CoreData.h>



@interface MedicalRecordDetailTableViewController ()
@property(strong,nonatomic) NSDictionary *selectedMedicalRecord;
@property (strong,nonatomic) NSDictionary *responseJSONData;
- (IBAction)createNewMedicalRecord:(id)sender;
@end

@implementation MedicalRecordDetailTableViewController

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


    NSString *medicalRecordID = [newMedicalRecordDic objectForKey:@"Id"];
    NSString *owner = [newMedicalRecordDic objectForKey:@"Owner"];
    NSString *creator = [newMedicalRecordDic objectForKey:@"Creator"];
    NSString *categoryID = [newMedicalRecordDic objectForKey:@"Category"];
    NSString *info = [newMedicalRecordDic objectForKey:@"Info"];
    NSString *time = [newMedicalRecordDic objectForKey:@"Time"];
    NSString *createdDate = [newMedicalRecordDic objectForKey:@"Created"];



    NSManagedObjectContext *context = [self managedObjectContext];
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


    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }else{
        NSLog(@"Save MedicalRecord success!");
    }
    [self.medicalRecordArray addObject:newMedicalRecordDic];
}


#pragma mark - Connect to API function
-(void)createMedicalRecordDataToAPI{

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
    //create JSON data to post to API
    // dateformater to convert to UTC time zone
    NSDateFormatter *dateFormaterToUTC = [[NSDateFormatter alloc] init];
    dateFormaterToUTC.timeStyle = NSDateFormatterNoStyle;
    dateFormaterToUTC.dateFormat = @"MM/dd/yyyy HH:mm:ss:SSS";
    [dateFormaterToUTC setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDate *createdDate = [dateFormaterToUTC dateFromString:[dateFormaterToUTC stringFromDate:[NSDate date]]];
    NSTimeInterval createdDateTimeInterval = [createdDate timeIntervalSince1970];

    NSDictionary *account = @{
                              @"Owner" :self.selectedPatientID,
                              @"Category":[self.selectedCategory objectForKey:@"Id"],
                              @"Time":[NSString stringWithFormat:@"%f",createdDateTimeInterval*1000],
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
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              //create new api no need load from core data when api fail
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
    self.navigationController.topViewController.title=@"MedicalRecord";
}

//-(void)viewWillDisappear:(BOOL)animated{
//    [super viewWillAppear:YES];
//    self.navigationController.topViewController.title=@"";
//    NSLog(@"unload");
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"TTTTTTTTT  %@",self.selectedCategory);
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
    return self.medicalRecordArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"medicalInfoCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:@"medicalInfoCell"];

    }
    // Configure the cell...
    NSDictionary *dic = [self.medicalRecordArray objectAtIndex:indexPath.row];
    NSString *time = [dic objectForKey:@"Time"];


    NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];

    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]/1000];

    NSDate *timeDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:timeDate]];

    cell.textLabel.text = [NSString stringWithFormat:@"%@",[dateFormatterToLocal stringFromDate:timeDateLocal]];
    //cell.detailTextLabel.text = @"details";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    self.selectedMedicalRecord = [self.medicalRecordArray objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"medicalNoteAndDetailInfo" sender:self];

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
    if ([[segue identifier] isEqualToString:@"medicalNoteAndDetailInfo"])
    {
        MedicalNoteTableViewController *medicalRecordDetail = [segue destinationViewController];
        medicalRecordDetail.medicalRecordDic = self.selectedMedicalRecord;
    }

}


- (IBAction)createNewMedicalRecord:(id)sender {
    [self createMedicalRecordDataToAPI];
    [self.tableView reloadData];
}
@end
