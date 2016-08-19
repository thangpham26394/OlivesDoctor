//
//  HeartBeatViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/8/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/heartbeat/filter"

#import "HeartBeatViewController.h"
#import "Olives-Bridging-Header.h"
#import <CoreData/CoreData.h>

@interface HeartBeatViewController ()

@property (weak, nonatomic) IBOutlet LineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) NSArray *heartBeatArray;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentController;
- (IBAction)changeSegment:(id)sender;
@property (strong,nonatomic) UIView *backgroundView;
@property (strong,nonatomic) UIActivityIndicatorView *  activityIndicator ;
@property (strong,nonatomic) UIWindow *currentWindow;
@property(strong,nonatomic) NSDate *startDate;
@end

@implementation HeartBeatViewController

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

-(void)loadHeartBeatDataFromAPIFromDate:(double)minTime toDate: (double)maxTime{

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
                                                  self.heartBeatArray = [self.responseJSONData objectForKey:@"Heartbeats"];
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
            [self loadHeartBeatDataFromAPIFromDate:fromdate*1000 toDate:todate*1000];

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
    NSMutableArray *valueArray = [[NSMutableArray alloc]init];


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
        NSMutableArray *totalValueInCurrentWeekDay = [[NSMutableArray alloc]init]; // content all the return value which have same day
        for (int index = 0; index<self.heartBeatArray.count; index++) {
            NSDictionary *currentDic = self.heartBeatArray[index];
            //get value
            NSString *rateValue = [currentDic objectForKey:@"Rate"];
            NSString *time = [currentDic objectForKey:@"Time"];


            NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]/1000];
            NSString *returnTime = [dateFormatterToLocal stringFromDate:currentDate];

            //add all the value which have same time with current time in week
            if ([returnTime isEqualToString:dayInWeek]) {
                [totalValueInCurrentWeekDay addObject:rateValue];
            }

        }


        //get the average value for a single week day if need
        if (totalValueInCurrentWeekDay.count >1) {
            // content more than 1 value take in current day
            double total = 0;
            double average = 0;
            for (int index = 0;index <totalValueInCurrentWeekDay.count ; index ++) {
                total += [[totalValueInCurrentWeekDay objectAtIndex:index] doubleValue];
            }
            average = total/totalValueInCurrentWeekDay.count;
            [valueArray addObject:[NSString stringWithFormat:@"%f",average]];
        }else if (totalValueInCurrentWeekDay.count ==1){
            //content only 1 value in current day
            [valueArray addObject:[totalValueInCurrentWeekDay objectAtIndex:0]];
        }
        else{
            //content no value in current day
            [valueArray addObject: [NSNull null]];
        }
    }






    [self setChart:timeArray withValue:valueArray];
    
}
#pragma mark - Chart View setting
-(void)setChart:(NSArray *)dataPoint withValue:(NSArray *) doubleValue {

    NSMutableArray <ChartDataEntry *> *dataEntries = [[NSMutableArray alloc]init];

    for (int i =0; i<dataPoint.count; i++) {
        if ([doubleValue objectAtIndex:i] != [NSNull null]) {
            ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:[[doubleValue objectAtIndex:i] doubleValue]  xIndex:i];
            [dataEntries addObject:dataEntry];
        }

    }


    LineChartDataSet *lineChartDataSet = [[LineChartDataSet alloc]initWithYVals:dataEntries label:@"HeartBeat"];
    LineChartData *lineCharData = [[LineChartData alloc] initWithXVals:dataPoint dataSet:lineChartDataSet];
    self.lineChartView.backgroundColor = [UIColor whiteColor];
    self.lineChartView.descriptionText = @"";
    self.lineChartView.xAxis.labelPosition = XAxisLabelPositionBottom;

    lineChartDataSet.colors = @[[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
    NSMutableArray *colorArray = [[NSMutableArray alloc]init];
    for (int i=0;i<doubleValue.count; i++) {
        [colorArray addObject:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
    }
    lineChartDataSet.circleColors = [colorArray copy];
    lineChartDataSet.circleRadius = 4.0f;
    [self.lineChartView animateWithXAxisDuration:1.0 yAxisDuration:2.0 easingOption:ChartEasingOptionEaseInOutQuart];
    lineChartDataSet.valueTextColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];
    self.lineChartView.data = lineCharData;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.heartBeatArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSDictionary *addDic = [self.addictionArray objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"heartBeatCell" forIndexPath:indexPath];
    NSDictionary *currentDic = [self.heartBeatArray objectAtIndex:indexPath.row];

    // Configure the cell...
    NSString *timeString = [currentDic objectForKey:@"Time"];
    NSString *rate = [currentDic objectForKey:@"Rate"];
    NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM:dd:yyyy"];
    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:[timeString doubleValue]/1000];



    cell.textLabel.text = [dateFormatterToLocal stringFromDate:timeDate];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",rate];//[addDic objectForKey:@"Note"];

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
