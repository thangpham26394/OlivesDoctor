//
//  AlgeryTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/allergy/filter"
#import "AlgeryTableViewController.h"
#import "AlgeryTableViewCell.h"
#import <CoreData/CoreData.h>


@interface AlgeryTableViewController ()
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *algeryArray;
@end

@implementation AlgeryTableViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)saveAlgeryToCoreData{

    //get the medical record of specific patient which data was returned from API
    self.algeryArray = [self.responseJSONData objectForKey:@"Allergies"];


    //delete all the current medical record of selected patient from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Algery"];
    NSMutableArray *algeryObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *algery;

    if (algeryObject.count >0) {

        for (int index=0; index < algeryObject.count; index++) {
            algery = [algeryObject objectAtIndex:index];
            if ([[algery valueForKey:@"ownerID"] isEqual:self.selectedPatientID]) {
                [context deleteObject:algery];//only delete algery that belong to selected Patient
                NSLog(@"Delete Algery success!");
            }
        }
    }

    //insert new medicalrecord of selected Patient into coredata
    for (int index=0; index<self.algeryArray.count;index++) {
        NSDictionary *algeryDic = [self.algeryArray objectAtIndex:index];

        NSString *algeryID = [algeryDic objectForKey:@"Id"];
        NSString *name = [algeryDic objectForKey:@"Name"];
        NSString *cause = [algeryDic objectForKey:@"Cause"];
        NSString *note = [algeryDic objectForKey:@"Note"];
        NSString *created = [algeryDic objectForKey:@"Created"];
        NSString *lastModified = [algeryDic objectForKey:@"LastModified"];
        NSString *owner = [algeryDic objectForKey:@"Owner"];


        //create new medical record object
        NSManagedObject *newAlgery = [NSEntityDescription insertNewObjectForEntityForName:@"Algery" inManagedObjectContext:context];

        //set value for each attribute of new patient before save to core data
        [newAlgery setValue: [NSString stringWithFormat:@"%@", algeryID] forKey:@"algeryID"];
        [newAlgery setValue: [NSString stringWithFormat:@"%@", name] forKey:@"name"];
        [newAlgery setValue: [NSString stringWithFormat:@"%@", cause] forKey:@"cause"];
        [newAlgery setValue: [NSString stringWithFormat:@"%@", note] forKey:@"note"];
        [newAlgery setValue: [NSString stringWithFormat:@"%@", created] forKey:@"created"];
        [newAlgery setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"lastModified"];
        [newAlgery setValue: [NSString stringWithFormat:@"%@", owner] forKey:@"ownerID"];


        NSError *error = nil;
        // Save the object to persistent store
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save Algery success!");
        }
    }
    
}

#pragma mark - Connect to API function

-(void)loadAlgeryFromCoreDataWhenAPIFail{
    NSMutableArray *algeryArrayForFailAPI = [[NSMutableArray alloc]init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Algery"];
    NSMutableArray *algeryObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *algery;
    for (int index =0; index<algeryObject.count; index++) {
        //get each patient in coredata
        algery = [algeryObject objectAtIndex:index];
        if ([[algery valueForKey:@"ownerID"] isEqual:self.selectedPatientID]) {
            NSDictionary *algeryDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [algery valueForKey:@"algeryID" ],@"Id",
                                           [algery valueForKey:@"ownerID" ],@"Owner",
                                           [algery valueForKey:@"name" ],@"Name",
                                           [algery valueForKey:@"cause" ],@"Cause",
                                           [algery valueForKey:@"note" ],@"Note",
                                           [algery valueForKey:@"created" ],@"Created",
                                           [algery valueForKey:@"lastModified" ],@"LastModified",

                                           nil];
            [algeryArrayForFailAPI addObject:algeryDic];
        }

    }
    self.algeryArray = (NSArray*)algeryArrayForFailAPI;

}

-(void)loadAlgeryDataFromAPI{

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
    NSDictionary *account = @{
                              @"Sort":@"1",
                              @"Owner":self.selectedPatientID
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
                                                  [self saveAlgeryToCoreData];
                                              }else{
                                                  [self loadAlgeryFromCoreDataWhenAPIFail];

                                              }

                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              [self loadAlgeryFromCoreDataWhenAPIFail];

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
    [self loadAlgeryDataFromAPI];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return self.algeryArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AlgeryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"algeryCell" forIndexPath:indexPath];
    NSDictionary *algeryDic = [self.algeryArray objectAtIndex:indexPath.row];
    cell.algeryNameLabel.text = [algeryDic objectForKey:@"Name"];
    cell.algeryCauseLabel.text = [algeryDic objectForKey:@"Cause"];
    cell.algeryNoteLabel.text = [algeryDic objectForKey:@"Note"];;
    // Configure the cell...
    return cell;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
