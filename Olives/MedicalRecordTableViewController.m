//
//  MedicalRecordTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/19/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/record/filter"
#import "MedicalRecordTableViewController.h"
#import "MedicalRecordDetailTableViewController.h"
#import "PickNewMedicalRecordViewController.h"
#import <CoreData/CoreData.h>

@interface MedicalRecordTableViewController ()
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSMutableArray *medicalCategoryArray;
@property (strong,nonatomic) NSArray *medicalRecordArray;
@property (strong,nonatomic) NSArray *selectedMedicalRecord;
@property (strong,nonatomic)NSDictionary *selectedCategory;

@end

@implementation MedicalRecordTableViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Medical Category";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.medicalCategoryArray = [[NSMutableArray alloc]init];
    [self loadMedicalRecordDataFromAPI];
    //check if there is new catagory added

    NSData *dictionaryData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"BrandNewCategoryOfId%@",self.selectedPatientID]];
    NSArray *newBlankCategoryArray = [NSKeyedUnarchiver unarchiveObjectWithData:dictionaryData];
    if (newBlankCategoryArray !=nil) {
        for (int index =0; index < newBlankCategoryArray.count; index++) {
            NSDictionary *newBlankCategory = newBlankCategoryArray[index];
            if (newBlankCategory !=nil) {
                BOOL isAlreadyHave = NO;
                //check if new category already have or not
                for (int index = 0; index <self.medicalCategoryArray.count; index++) {
                    if ([ [NSString stringWithFormat:@"%@",[self.medicalCategoryArray[index] objectForKey:@"Id"]] isEqual:[NSString stringWithFormat:@"%@",[newBlankCategory objectForKey:@"Id"]]] ) {
                        isAlreadyHave = YES;
                    }
                }
                //if new category isn't in current category array then add new
                if (!isAlreadyHave) {
                    [self.medicalCategoryArray addObject:newBlankCategory];
                }
            }
        }
    }


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

-(void)loadMedicalRecordDataFromAPI{

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
                              @"Partner":self.selectedPatientID,
                              @"Mode" :@"0",
                              @"Sort" :  @"0",
                              @"Direction" : @"0"
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
                                                  [self loadMedicalRecordFromCoreDataWhenAPIFail];

                                              }

                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              [self loadMedicalRecordFromCoreDataWhenAPIFail];

                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}

-(void)saveMedicalRecordToCoreData{
    //get the medical record of specific patient which data was returned from API
    self.medicalRecordArray = [self.responseJSONData objectForKey:@"MedicalRecords"];
    //delete all the current medical record of selected patient from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
    NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalRecord;
    if (medicalRecordObject.count >0) {

        for (int index=0; index < medicalRecordObject.count; index++) {
            medicalRecord = [medicalRecordObject objectAtIndex:index];
            if ([[medicalRecord valueForKey:@"ownerID"] isEqual:self.selectedPatientID]) {
                [context deleteObject:medicalRecord];//only delete medical record that belong to selected Patient
                NSLog(@"Delete MedicalRecord success!");
            }

        }
    }

    //insert new medicalrecord of selected Patient into coredata
    for (int index=0; index<self.medicalRecordArray.count;index++) {
        NSDictionary *medicalRecordDic = [self.medicalRecordArray objectAtIndex:index];

        NSString *medicalRecordID = [medicalRecordDic objectForKey:@"Id"];
        NSString *owner = [[medicalRecordDic objectForKey:@"Owner"] objectForKey:@"Id"];
        NSString *creator = [[medicalRecordDic objectForKey:@"Creator"] objectForKey:@"Id"];
        NSDictionary *category = [medicalRecordDic objectForKey:@"Category"];
        NSString *categoryID = [category objectForKey:@"Id"];
        NSString *info = [medicalRecordDic objectForKey:@"Info"];
        NSString *time = [medicalRecordDic objectForKey:@"Time"];
        NSString *createdDate = [medicalRecordDic objectForKey:@"Created"];
        NSString *lastModified = [medicalRecordDic objectForKey:@"LastModified"];

        BOOL isAlreadyHave = NO;
        //check if new category already have or not
        for (int index = 0; index <self.medicalCategoryArray.count; index++) {
            if ([ [NSString stringWithFormat:@"%@",[self.medicalCategoryArray[index] objectForKey:@"Id"]] isEqual:[NSString stringWithFormat:@"%@",[category objectForKey:@"Id"]]] ) {
                isAlreadyHave = YES;
            }
        }
        //if new category isn't in current category array then add new
        if (!isAlreadyHave) {
            [self.medicalCategoryArray addObject:category];
            [self saveMedicalCategoryToCoreData:category];
        }



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
        [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", lastModified] forKey:@"lastModified"];

        NSError *error = nil;
        // Save the object to persistent store
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save MedicalRecord success!");
        }
    }
}

-(void)saveMedicalCategoryToCoreData:(NSDictionary*)categoryDic{

    NSString *categoryID = [categoryDic objectForKey:@"Id"];
    NSString *categoryName = [categoryDic objectForKey:@"Name"];

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalCategories"];
    NSMutableArray *medicalCategoryObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalCategory;

    //if category already have in coredata then update the name of category which have same Id
    BOOL inCoreDataAlready = NO;
    if (medicalCategoryObject.count >0) {
        for (int index=0; index < medicalCategoryObject.count; index++) {
            medicalCategory = [medicalCategoryObject objectAtIndex:index];
            if ([[NSString stringWithFormat:@"%@",categoryID] isEqual:[medicalCategory valueForKey:@"medicalCategoryID"] ]) {
                [medicalCategory setValue:categoryName forKey:@"name"];
                NSLog(@"Update MedicalRecordCategory success!");
                inCoreDataAlready = YES;
            }
        }
    }

    //if category don't have in coredata yet then add new
    if (!inCoreDataAlready) {
        //create new patient object
        NSManagedObject *newMedicalRecord  = [NSEntityDescription insertNewObjectForEntityForName:@"MedicalCategories" inManagedObjectContext:context];
        [newMedicalRecord setValue:[NSString stringWithFormat:@"%@", categoryID]  forKey:@"medicalCategoryID"];
        [newMedicalRecord setValue:categoryName forKey:@"name"];
        // Save the object to persistent store
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save MedicalRecordCategory success!");
        }
    }

}

-(void)loadMedicalRecordFromCoreDataWhenAPIFail{
    NSMutableArray *medicalRecordForFailAPiArray = [[NSMutableArray alloc] init];
    NSMutableArray *medicalCategoryForFailAPiArray = [[NSMutableArray alloc] init];

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
    NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalRecord;

    for (int index =0; index<medicalRecordObject.count; index++) {
        //get each patient in coredata
        medicalRecord = [medicalRecordObject objectAtIndex:index];

        if ([[medicalRecord valueForKey:@"ownerID" ] isEqual:self.selectedPatientID]) {
            //get medical record category
            NSFetchRequest *fetchRequestCategory = [[NSFetchRequest alloc] initWithEntityName:@"MedicalCategories"];
            NSMutableArray *medicalCategoryObject = [[context executeFetchRequest:fetchRequestCategory error:nil] mutableCopy];
            NSManagedObject *medicalCategory;
            NSDictionary *medicalCategoryDic;

            for (int i=0; i<medicalCategoryObject.count; i++) {
                medicalCategory = [medicalCategoryObject objectAtIndex:i];
                //check if the current medical category id is equal with medical record id
                if ([[medicalCategory valueForKey:@"medicalCategoryID"] isEqual:[medicalRecord valueForKey:@"categoryID" ]]) {
                    medicalCategoryDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [medicalCategory valueForKey:@"medicalCategoryID" ],@"Id",
                                          [medicalCategory valueForKey:@"name" ],@"Name",
                                          nil];
                    
                    BOOL isAlreadyHave = NO;
                    //check if new category already have or not
                    for (int index = 0; index <medicalCategoryForFailAPiArray.count; index++) {
                        if ([ [NSString stringWithFormat:@"%@",[medicalCategoryForFailAPiArray[index] objectForKey:@"Id"]] isEqual:[NSString stringWithFormat:@"%@",[medicalCategoryDic objectForKey:@"Id"]]] ) {
                            isAlreadyHave = YES;
                        }
                    }
                    //if new category isn't in current category array then add new
                    if (!isAlreadyHave) {
                        [medicalCategoryForFailAPiArray addObject:medicalCategoryDic];
                    }

                }
            }


            NSDictionary *medicalRecordDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [medicalRecord valueForKey:@"medicalRecordID" ],@"Id",
                                              [medicalRecord valueForKey:@"ownerID" ],@"Owner",
                                              [medicalRecord valueForKey:@"creatorID" ],@"Creator",
                                              medicalCategoryDic,@"Category",
                                              [medicalRecord valueForKey:@"info" ],@"Info",
                                              [medicalRecord valueForKey:@"time" ],@"Time",
                                              [medicalRecord valueForKey:@"createdDate" ],@"Created",
                                              [medicalRecord valueForKey:@"lastModified" ],@"LastModified",
                                              nil];
            [medicalRecordForFailAPiArray addObject:medicalRecordDic];
        }

    }
    self.medicalRecordArray = (NSArray*)medicalRecordForFailAPiArray;
    self.medicalCategoryArray = medicalCategoryForFailAPiArray;
}

-(IBAction)addInfo:(id)sender{
    NSLog(@"add medical");
    [self performSegueWithIdentifier:@"pickMedicalRecord" sender:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.medicalCategoryArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"medicalCategoryCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:@"medicalCategoryCell"];

    }
    // Configure the cell...
    cell.textLabel.text = [self.medicalCategoryArray[indexPath.row] objectForKey:@"Name"];
    //cell.detailTextLabel.text = @"details";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // get the selected category
    NSMutableArray *medicalRecordArray = [[NSMutableArray alloc]init];
    NSString *selectedCategoryID = [NSString stringWithFormat:@"%@",[[self.medicalCategoryArray objectAtIndex:indexPath.row] objectForKey:@"Id"]];

    //select all the medical record that belong to selected category
    for (int index = 0; index < self.medicalRecordArray.count; index++) {
        NSDictionary *dic = [self.medicalRecordArray objectAtIndex:index];
        if ([[NSString stringWithFormat:@"%@",[[dic objectForKey:@"Category"] objectForKey:@"Id"]] isEqual:selectedCategoryID]) {
            [medicalRecordArray addObject:dic];
        }
    }


    self.selectedMedicalRecord = medicalRecordArray;
    self.selectedCategory = [self.medicalCategoryArray objectAtIndex:indexPath.row] ;
    [self performSegueWithIdentifier:@"showMedicalRecord" sender:self];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        BOOL permission = YES;
        //check if selected category can delete or not < only blank category with no medical record related to selected patient can be deleted >
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
        NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        NSManagedObject *medicalRecord;
        if (medicalRecordObject.count >0) {

            for (int index=0; index < medicalRecordObject.count; index++) {
                medicalRecord = [medicalRecordObject objectAtIndex:index];

                //check if current medical record is belong to selected patient or not
                if ([[medicalRecord valueForKey:@"ownerID"] isEqual:self.selectedPatientID]) {

                    NSString *selectedCategoryID = [NSString stringWithFormat:@"%@",[[self.medicalCategoryArray objectAtIndex:indexPath.row] objectForKey:@"Id"]];

                    //check if selected medical category is category of any medical record or not
                    if ([[medicalRecord valueForKey:@"categoryID"] isEqual:selectedCategoryID]) {
                        permission = NO;
                    }
                }
                
            }
        }


        [self showAlertViewWhenDelete:indexPath withPermission:permission];
    }
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

- (IBAction)unwindChoseNewMedicalRecordViewController:(UIStoryboardSegue *)unwindSegue
{
        PickNewMedicalRecordViewController* sourceViewController = unwindSegue.sourceViewController;
    
        if (sourceViewController.didAddCategory)
        {
            NSDictionary *brandNewcategory = sourceViewController.selectedCategory;
            //check if this brand new category is saved in Nsuserdefault or not
            NSData *dictionaryData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"BrandNewCategoryOfId%@",self.selectedPatientID]];
            NSMutableArray *categoryArray = [NSKeyedUnarchiver unarchiveObjectWithData:dictionaryData];
            if (categoryArray ==nil) {
                categoryArray = [[NSMutableArray alloc]init];
            }
            BOOL isAlreadyHave = NO;
            for (int index =0; index < categoryArray.count; index ++) {
                NSDictionary *currentBrandNewCategory = categoryArray[index];
                if ([[NSString stringWithFormat:@"%@",[currentBrandNewCategory objectForKey:@"Id"]] isEqual:[NSString stringWithFormat:@"%@",[brandNewcategory objectForKey:@"Id"]]]) {
                    isAlreadyHave = YES;
                }
            }
            if (!isAlreadyHave) {
                [categoryArray addObject:brandNewcategory];
            }

            //save to NSuserdefault
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:categoryArray];
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:[NSString stringWithFormat:@"BrandNewCategoryOfId%@",self.selectedPatientID]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }

}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//     Get the new view controller using [segue destinationViewController].
//     Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"showMedicalRecord"])
    {
        MedicalRecordDetailTableViewController *medicalRecordDetail = [segue destinationViewController];
        medicalRecordDetail.medicalRecordArray = (NSMutableArray*)self.selectedMedicalRecord;
        medicalRecordDetail.selectedCategory = self.selectedCategory;
        medicalRecordDetail.selectedPatientID = self.selectedPatientID;
    }
}


-(void)deleteCategoryFromNSUserdefault:(NSDictionary*)category{

    //check if this brand new category is saved in Nsuserdefault or not
    NSData *dictionaryData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"BrandNewCategoryOfId%@",self.selectedPatientID]];
    NSMutableArray *categoryArray = [NSKeyedUnarchiver unarchiveObjectWithData:dictionaryData];
    if (categoryArray ==nil) {
        return; //nothing left to delete
    }

    //find out the category to delete
    for (int index =0; index < categoryArray.count; index ++) {
        NSDictionary *currentBrandNewCategory = categoryArray[index];
        if ([[NSString stringWithFormat:@"%@",[currentBrandNewCategory objectForKey:@"Id"]] isEqual:[NSString stringWithFormat:@"%@",[category objectForKey:@"Id"]]]) {
            [categoryArray removeObject:currentBrandNewCategory];
        }
    }


    //save to NSuserdefault
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:categoryArray];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:[NSString stringWithFormat:@"BrandNewCategoryOfId%@",self.selectedPatientID]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)showAlertViewWhenDelete:(NSIndexPath *)indexPath withPermission:(BOOL)permission{
    UIAlertController* alert;

    if (permission) {
        //if can delete
        alert = [UIAlertController alertControllerWithTitle:@"Are you sure"
                                                    message:@"This blank category will be deleted"
                                             preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //sent request to API here
                                                             NSLog(@"OK Action!");


                                                             //delete in NSUser default
                                                             NSDictionary *categoryToDelete = [self.medicalCategoryArray objectAtIndex:indexPath.row];
                                                             [self deleteCategoryFromNSUserdefault:categoryToDelete];
                                                             //delete in category array
                                                             [self.medicalCategoryArray removeObjectAtIndex:indexPath.row];
                                                             //delete in tableview
                                                             [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                                         }];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * action) {
                                                                 NSLog(@"cancel Action!");
                                                             }];


        [alert addAction:OKAction];
        [alert addAction:cancelAction];
    }else{
        //can not delete
        alert = [UIAlertController alertControllerWithTitle:@"Can not delete"
                                                    message:@"This category content medical record which only patient can delete!"
                                             preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //sent request to API here
                                                             NSLog(@"OK Action!");

                                                         }];
        [alert addAction:OKAction];

    }

    [self presentViewController:alert animated:YES completion:nil];
}
@end
