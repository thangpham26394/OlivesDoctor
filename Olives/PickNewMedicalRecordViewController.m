//
//  PickNewMedicalRecordViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/1/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/category/filter"
#import "PickNewMedicalRecordViewController.h"
#import "MedicalRecordTableViewController.h"
#import <CoreData/CoreData.h>
@interface PickNewMedicalRecordViewController ()
@property (weak, nonatomic) IBOutlet UIPickerView *categoryPickerView;

@property (strong,nonatomic) NSArray *categoryArray;
@property (strong,nonatomic) NSDictionary *responseJSONData;
- (IBAction)choseCategoryButton:(id)sender;
@end

@implementation PickNewMedicalRecordViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)saveMedicalCategoryToCoreData{
    self.categoryArray = [self.responseJSONData objectForKey:@"MedicalCategories"];
    self.selectedCategory = self.categoryArray[0];
    for (int index =0; index <self.categoryArray.count; index ++) {
        [self saveMedicalCategoryToCoreData:self.categoryArray[index]];
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
        NSManagedObject *newMedicalCategory = [NSEntityDescription insertNewObjectForEntityForName:@"MedicalCategories" inManagedObjectContext:context];
        [newMedicalCategory setValue:[NSString stringWithFormat:@"%@", categoryID]  forKey:@"medicalCategoryID"];
        [newMedicalCategory setValue:categoryName forKey:@"name"];
        // Save the object to persistent store
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }else{
            NSLog(@"Save MedicalRecordCategory success!");
        }
    }
    
}
-(void)loadMedicalCategoryFromCoreDataWhenAPIFail{
    NSMutableArray *medicalCategoryForFailAPiArray = [[NSMutableArray alloc] init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalCategories"];
    NSMutableArray *categoryObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *category;

    //load all the category in coredata
    for (int index =0; index<categoryObject.count; index++) {
        //get each patient in coredata
        category = [categoryObject objectAtIndex:index];
        [medicalCategoryForFailAPiArray addObject:category];// add current category
    }
    self.categoryArray = medicalCategoryForFailAPiArray;
}


#pragma mark - Connect to API function

-(void)loadMedicalRecordCategoryDataFromAPI{

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
                                                  [self saveMedicalCategoryToCoreData];
                                              }else{
                                                  [self loadMedicalCategoryFromCoreDataWhenAPIFail];

                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              [self loadMedicalCategoryFromCoreDataWhenAPIFail];

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
    [self loadMedicalRecordCategoryDataFromAPI];
    [self.categoryPickerView reloadAllComponents];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.categoryArray = @[@"Item 1", @"Item 2", @"Item 3", @"Item 4", @"Item 5", @"Item 6",@"Item 1", @"Item 2", @"Item 3", @"Item 4", @"Item 5", @"Item 6",@"Item 1", @"Item 2", @"Item 3", @"Item 4", @"Item 5", @"Item 6",@"Item 1", @"Item 2", @"Item 3", @"Item 4", @"Item 5", @"Item 6",@"Item 1", @"Item 2", @"Item 3", @"Item 4", @"Item 5", @"Item 6"];
    self.categoryPickerView.dataSource = self;
    self.categoryPickerView.delegate = self;
    self.didAddCategory = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.categoryArray.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.categoryArray[row] objectForKey:@"Name"];
}

// Catpure the picker view selection
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{

    self.selectedCategory = self.categoryArray[row];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//    if ([[segue identifier] isEqualToString:@"addNewCategory"])
//    {
//        MedicalRecordTableViewController *medicalRecordTableView = [segue destinationViewController];
//        medicalRecordTableView.addNewCategory = self.selectedCategory;
//    }
//}


- (IBAction)choseCategoryButton:(id)sender {
    //[self performSegueWithIdentifier:@"addNewCategory" sender:self];
    self.didAddCategory = YES;
}
@end
