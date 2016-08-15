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
@property(strong,nonatomic) UITextField *stringTextField;
@property(strong,nonatomic) UIDatePicker *experimentDatePicker;
@property(strong,nonatomic) UIView *popupView;
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

-(void)reloadDataFromCoreData{
    //get the newest medical record data which have just saved to coredata
    NSMutableArray *medicalRecordArray = [[NSMutableArray alloc]init];

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
    NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalRecord;

    for (int index =0; index<medicalRecordObject.count; index++) {
        //get each patient in coredata
        medicalRecord = [medicalRecordObject objectAtIndex:index];
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
            }
        }

        NSDictionary *medicalRecordDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [medicalRecord valueForKey:@"medicalRecordID" ],@"Id",
                                          [medicalRecord valueForKey:@"ownerID" ],@"Owner",
                                          [medicalRecord valueForKey:@"creatorID" ],@"Creator",
                                          medicalCategoryDic,@"Category",
                                          [medicalRecord valueForKey:@"info" ],@"Info",
                                          [medicalRecord valueForKey:@"time" ],@"Time",
                                          [medicalRecord valueForKey:@"name" ],@"Name",
                                          [medicalRecord valueForKey:@"createdDate" ],@"Created",
                                          [medicalRecord valueForKey:@"lastModified" ],@"LastModified",

                                          nil];

//        if ([[medicalRecord valueForKey:@"medicalRecordID" ] isEqual:[NSString stringWithFormat:@"%@",[self.medicalRecordDic objectForKey:@"Id"]]]) {
//            self.medicalRecordDic = medicalRecordDic;
//        }
        [medicalRecordArray addObject:medicalRecordDic];

    }

    self.medicalRecordArray = medicalRecordArray;
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
    NSString *name = [newMedicalRecordDic objectForKey:@"Name"];


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
    [newMedicalRecord setValue: [NSString stringWithFormat:@"%@", name] forKey:@"name"];

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
    NSDate *createdDate = [dateFormaterToUTC dateFromString:[dateFormaterToUTC stringFromDate:self.experimentDatePicker.date]];
    NSTimeInterval createdDateTimeInterval = [createdDate timeIntervalSince1970];

    NSDictionary *account = @{
                              @"Owner" :self.selectedPatientID,
                              @"Category":[self.selectedCategory objectForKey:@"Id"],
                              @"Time":[NSString stringWithFormat:@"%f",createdDateTimeInterval*1000],
                              @"Name":self.stringTextField.text,
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"MedicalRecord";
    [self reloadDataFromCoreData];
    [self.tableView reloadData];
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
    NSString *name = [dic objectForKey:@"Name"];
    NSString *time = [dic objectForKey:@"Time"];

    if ((id)name != [NSNull null] && ![name isEqual:[NSString stringWithFormat:@"<null>"]])  {
        cell.textLabel.text = name;
    }else{
        cell.textLabel.text = @"no name";
    }


    NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];

    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]/1000];

    NSDate *timeDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:timeDate]];

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",[dateFormatterToLocal stringFromDate:timeDateLocal]];
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

-(void)showPopUpView{
    // show popup view here
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;


    self.popupView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.popupView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];

    UIView *myView = [[UIView alloc]initWithFrame:CGRectMake(20, 150, screenWidth-40, 280)];
    myView.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    myView.layer.cornerRadius = 10.0f;

    //create OK button
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth-40)/2,240, (screenWidth-40)/2, 40)];
    okButton.backgroundColor = [UIColor whiteColor];
    [okButton setTitle: @"OK" forState: UIControlStateNormal];
    [okButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    [okButton setTitleColor:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0] forState:UIControlStateNormal];

    UIBezierPath *maskPathOK = [UIBezierPath bezierPathWithRoundedRect:okButton.bounds byRoundingCorners:(UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayerOK = [[CAShapeLayer alloc] init];
    maskLayerOK.frame = self.popupView.bounds;
    maskLayerOK.path  = maskPathOK.CGPath;
    okButton.layer.mask = maskLayerOK;
    [okButton addTarget:self action:@selector(okButtonActionHightLight:) forControlEvents:UIControlEventTouchDown];
    [okButton addTarget:self action:@selector(okButtonActionNormal:) forControlEvents:UIControlEventTouchUpInside];



    //create cancel button
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0,240, (screenWidth-40)/2-1, 40)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton setTitle: @"Cancel" forState: UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0]];
    [cancelButton setTitleColor:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0] forState:UIControlStateNormal];

    UIBezierPath *maskPathCancel = [UIBezierPath bezierPathWithRoundedRect:cancelButton.bounds byRoundingCorners:(UIRectCornerBottomLeft) cornerRadii:CGSizeMake(10.0, 10.0)];

    CAShapeLayer *maskLayerCancel = [[CAShapeLayer alloc] init];
    maskLayerCancel.frame = self.popupView.bounds;
    maskLayerCancel.path  = maskPathCancel.CGPath;
    cancelButton.layer.mask = maskLayerCancel;
    [cancelButton addTarget:self action:@selector(cancelButtonActionHightLight:) forControlEvents:UIControlEventTouchDown];
    [cancelButton addTarget:self action:@selector(cancelButtonActionNormal:) forControlEvents:UIControlEventTouchUpInside];


    //Title Label
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,20, (screenWidth-40), 40)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0]];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleLabel setTextColor:[UIColor blackColor]];
    titleLabel.text = @"New medical record";

    //top content View
    UIView *topContentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth-40, 239)];
    topContentView.backgroundColor = [UIColor whiteColor];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:topContentView.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.popupView.bounds;
    maskLayer.path  = maskPath.CGPath;
    topContentView.layer.mask = maskLayer;

    //text Field for string
    self.stringTextField = [[UITextField alloc]initWithFrame:CGRectMake(70, 100, screenWidth-130, 30)];
    [self.stringTextField  setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    self.stringTextField .layer.cornerRadius = 5.0f;




    //name Label
    UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(10,100, 50, 30)];
    [nameLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15.0]];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [nameLabel setTextColor:[UIColor blackColor]];
    nameLabel.text = @"Name";


    //name Label
    UILabel *timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(10,140, 50, 30)];
    [timeLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15.0]];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    [timeLabel setTextColor:[UIColor blackColor]];
    timeLabel.text = @"Time";

    self.experimentDatePicker = [[UIDatePicker alloc]initWithFrame:CGRectMake(10,165, screenWidth-80, 60)];
    self.experimentDatePicker.datePickerMode = UIDatePickerModeDate;


    [topContentView addSubview:timeLabel];
    [topContentView addSubview:self.experimentDatePicker];
    [topContentView addSubview:titleLabel];
    [topContentView addSubview:self.stringTextField ];
    [topContentView addSubview:nameLabel];
    [myView addSubview:topContentView];
    [myView addSubview:okButton];
    [myView addSubview:cancelButton];

    [self.popupView addSubview:myView];
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self.popupView];


}

-(IBAction)okButtonActionHightLight:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor lightGrayColor];
}
-(IBAction)cancelButtonActionHightLight:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor lightGrayColor];
}

//action to call to add or update api
-(IBAction)okButtonActionNormal:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor whiteColor];
    [self.stringTextField resignFirstResponder];
    [self createMedicalRecordDataToAPI];
    [self.tableView reloadData];
    [UIView animateWithDuration:0.5
                     animations:^{self.popupView .alpha = 0.0;}
                     completion:^(BOOL finished){ [self.popupView removeFromSuperview]; }];
}
//dissmiss popup view
-(IBAction)cancelButtonActionNormal:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor whiteColor];
    [self.stringTextField resignFirstResponder];
    NSLog(@"Cancel ACtion");
    [UIView animateWithDuration:0.5
                     animations:^{self.popupView .alpha = 0.0;}
                     completion:^(BOOL finished){ [self.popupView removeFromSuperview]; }];
}



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
    [self showPopUpView];
    
}
@end
