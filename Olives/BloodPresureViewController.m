//
//  BloodPresureViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL_BLOODPRESSURE @"http://olive.azurewebsites.net/api/bloodpressure/filter"

#import "BloodPresureViewController.h"
#import "Olives-Bridging-Header.h"
#import <CoreData/CoreData.h>


@interface BloodPresureViewController ()
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *bloodPressureArray;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(strong,nonatomic) NSDate *startDate;
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;
- (IBAction)changeSegment:(id)sender;
@property (weak, nonatomic) IBOutlet LineChartView *lineChartView;



@end

@implementation BloodPresureViewController


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

-(void)loadBloodPressureDataFromAPIFromDate:(double)minTime toDate: (double)maxTime{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL_BLOODPRESSURE];
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
                              @"Owner":self.selectedPatientID,
                              @"MinTime":[NSString stringWithFormat:@"%f",minTime],
                              @"MaxTime":[NSString stringWithFormat:@"%f",maxTime],
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
                                                  self.bloodPressureArray = [self.responseJSONData objectForKey:@"BloodPressures"];
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self.tableView reloadData];
                                                  });

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

-(void)configModeForDisplay:(NSInteger)totalDays{
    [self.activityIndicator startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            // Do any additional setup after loading the view.
            NSCalendar *cal = [NSCalendar currentCalendar];
            NSDate* today = [NSDate date];
            //start date for init mode week.
            self.startDate = [cal dateByAddingUnit:NSCalendarUnitDay
                                             value:-totalDays+1
                                            toDate:today
                                           options:0];

            NSTimeInterval todate = [today timeIntervalSince1970];
            NSTimeInterval fromdate = [self.startDate timeIntervalSince1970];
            [self loadBloodPressureDataFromAPIFromDate:fromdate*1000 toDate:todate*1000];

            [self displayDataToChartViewWithTotalDays:totalDays fromStartDate:self.startDate];
            [self.tableView reloadData];

            [self.activityIndicator stopAnimating];
            [self.backgroundView removeFromSuperview];
        });
    });
    
}
-(void)viewDidAppear:(BOOL)animated{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.backgroundView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = CGPointMake(self.backgroundView .frame.size.width/2, self.backgroundView .frame.size.height/2);
    [self.backgroundView  addSubview:self.activityIndicator];
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self.backgroundView];
    [currentWindow bringSubviewToFront:self.backgroundView];


    [self configModeForDisplay:7];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.segmentController.tintColor = [UIColor colorWithRed:0/255.0 green:150/255.0 blue:136/255.0 alpha:1.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)displayDataToChartViewWithTotalDays:(NSInteger) total fromStartDate:(NSDate*)startDate{


    NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM:dd:yyyy"];

    NSCalendar *cal = [NSCalendar currentCalendar];

    NSMutableArray *timeArray = [[NSMutableArray alloc]init];
    NSMutableArray *diastolicArray = [[NSMutableArray alloc]init]; //Diastolic
    NSMutableArray *systolicArray = [[NSMutableArray alloc]init];//Systolic

    //create an array content 7 days in week
    for (int index =0; index <total; index++) {
        NSDate *displayDate = [cal dateByAddingUnit:NSCalendarUnitDay
                                              value:index
                                             toDate:startDate
                                            options:0];

        //day in week
        NSString *currenDateInWeek = [dateFormatterToLocal stringFromDate:displayDate];
        [timeArray addObject:currenDateInWeek]; //add day in week, this array will have 7 elements only
    }






    //add value for value array -> only 7 value
    for (int index = 0; index < timeArray.count; index ++) {
        NSString *dayInWeek = [timeArray objectAtIndex:index];

        //go through all return data array
        NSMutableArray *totalDiastolicInCurrentWeekDay = [[NSMutableArray alloc]init]; // content all the return Diastolic which have same day
        NSMutableArray *totalSystolicInCurrentWeekDay = [[NSMutableArray alloc]init]; // content all the return value Systolic have same day
        for (int index = 0; index<self.bloodPressureArray.count; index++) {
            NSDictionary *currentDic = self.bloodPressureArray[index];
            //get value
            NSString *diastolic = [currentDic objectForKey:@"Diastolic"];
            NSString *systolic = [currentDic objectForKey:@"Systolic"];
            NSString *time = [currentDic objectForKey:@"Time"];


            NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]/1000];
            NSString *returnTime = [dateFormatterToLocal stringFromDate:currentDate];

            //add all the value which have same time with current time in week
            if ([returnTime isEqualToString:dayInWeek]) {
                [totalDiastolicInCurrentWeekDay addObject:diastolic];
                [totalSystolicInCurrentWeekDay addObject:systolic];
            }

        }


        //get the average diastolic for a single week day if need
        if (totalDiastolicInCurrentWeekDay.count >1) {
            // content more than 1 value take in current day
            double total = 0;
            double average = 0;
            for (int index = 0;index <totalDiastolicInCurrentWeekDay.count ; index ++) {
                total += [[totalDiastolicInCurrentWeekDay objectAtIndex:index] doubleValue];
            }
            average = total/totalDiastolicInCurrentWeekDay.count;
            [diastolicArray addObject:[NSString stringWithFormat:@"%f",average]];
        }else if (totalDiastolicInCurrentWeekDay.count ==1){
            //content only 1 value in current day
            [diastolicArray addObject:[totalDiastolicInCurrentWeekDay objectAtIndex:0]];
        }
        else{
            //content no value in current day
            [diastolicArray addObject: [NSNull null]];
        }

        //get the average diastolic for a single week day if need
        if (totalSystolicInCurrentWeekDay.count >1) {
            // content more than 1 value take in current day
            double total = 0;
            double average = 0;
            for (int index = 0;index <totalSystolicInCurrentWeekDay.count ; index ++) {
                total += [[totalSystolicInCurrentWeekDay objectAtIndex:index] doubleValue];
            }
            average = total/totalSystolicInCurrentWeekDay.count;
            [systolicArray addObject:[NSString stringWithFormat:@"%f",average]];
        }else if (totalSystolicInCurrentWeekDay.count ==1){
            //content only 1 value in current day
            [systolicArray addObject:[totalSystolicInCurrentWeekDay objectAtIndex:0]];
        }
        else{
            //content no value in current day
            [systolicArray addObject: [NSNull null]];
        }




    }






    [self setChart:timeArray withValue1:diastolicArray andValue2:systolicArray];

}
#pragma mark - Chart View setting
-(void)setChart:(NSArray *)dataPoint withValue1:(NSArray *) doubleValue1 andValue2: (NSArray *) doubleValue2{

    NSMutableArray <ChartDataEntry *> *dataEntries1 = [[NSMutableArray alloc]init];
    NSMutableArray <ChartDataEntry *> *dataEntries2 = [[NSMutableArray alloc]init];


    for (int i =0; i<dataPoint.count; i++) {
        if ([doubleValue1 objectAtIndex:i] != [NSNull null]) {
            ChartDataEntry *dataEntry1 = [[ChartDataEntry alloc]initWithValue:[[doubleValue1 objectAtIndex:i] doubleValue]  xIndex:i];
            [dataEntries1 addObject:dataEntry1];
        }
    }
    for (int i =0; i<dataPoint.count; i++) {
        if ([doubleValue2 objectAtIndex:i] != [NSNull null]) {
            ChartDataEntry *dataEntry2 = [[ChartDataEntry alloc]initWithValue:[[doubleValue2 objectAtIndex:i] doubleValue]  xIndex:i];
            [dataEntries2 addObject:dataEntry2];
        }
    }

    //config line chart 1
    LineChartDataSet *lineChartDataSet1 = [[LineChartDataSet alloc]initWithYVals:dataEntries1 label:@"Diastolic"];

    lineChartDataSet1.colors = @[[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
    NSMutableArray *colorArray = [[NSMutableArray alloc]init];
    for (int i=0;i<doubleValue1.count; i++) {
        [colorArray addObject:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
    }
    lineChartDataSet1.circleColors = [colorArray copy];
    lineChartDataSet1.circleRadius = 4.0f;



    [self.lineChartView animateWithXAxisDuration:0 yAxisDuration:2.0 easingOption:ChartEasingOptionEaseInOutQuart];
    lineChartDataSet1.valueTextColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];

    //config line chart 2
    LineChartDataSet *lineChartDataSet2 = [[LineChartDataSet alloc]initWithYVals:dataEntries2 label:@"Systolic"];
    lineChartDataSet2.colors = @[[UIColor colorWithRed:67/255.0 green:68/255.0 blue:149/255.0 alpha:1.0]];
    colorArray = [[NSMutableArray alloc]init];
    for (int i=0;i<doubleValue1.count; i++) {
        [colorArray addObject:[UIColor colorWithRed:67/255.0 green:68/255.0 blue:149/255.0 alpha:1.0]];
    }
    lineChartDataSet2.circleColors = [colorArray copy];
    lineChartDataSet2.circleRadius = 4.0f;
    [self.lineChartView animateWithXAxisDuration:0 yAxisDuration:2.0 easingOption:ChartEasingOptionEaseInOutQuart];
    lineChartDataSet2.valueTextColor = [UIColor colorWithRed:67/255.0 green:68/255.0 blue:149/255.0 alpha:1.0];


    NSMutableArray *dataSets = [[NSMutableArray alloc] init];
    [dataSets addObject:lineChartDataSet1];
    [dataSets addObject:lineChartDataSet2];

    LineChartData *lineCharData = [[LineChartData alloc] initWithXVals:dataPoint dataSets:dataSets];
    self.lineChartView.backgroundColor = [UIColor whiteColor];
    self.lineChartView.descriptionText = @"";
    self.lineChartView.xAxis.labelPosition = XAxisLabelPositionBottom;




    self.lineChartView.data = lineCharData;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bloodPressureArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    NSDictionary *addDic = [self.addictionArray objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bloodPressureCell" forIndexPath:indexPath];
    NSDictionary *currentDic = [self.bloodPressureArray objectAtIndex:indexPath.row];

    // Configure the cell...
    NSString *timeString = [currentDic objectForKey:@"Time"];
    NSString *diastolic = [currentDic objectForKey:@"Diastolic"];
    NSString *systolic = [currentDic objectForKey:@"Systolic"];
    NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM:dd:yyyy"];
    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:[timeString doubleValue]/1000];



    cell.textLabel.text = [dateFormatterToLocal stringFromDate:timeDate];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@/%@",diastolic,systolic];//[addDic objectForKey:@"Note"];

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}


- (IBAction)changeSegment:(id)sender {
    switch (self.segmentController.selectedSegmentIndex)
    {
        case 0:
            [self configModeForDisplay:7];
            break;
        case 1:
            [self configModeForDisplay:30];
            break;
        case 2:
            [self configModeForDisplay:90];
            break;
        default:
            break;
    }
}

@end
