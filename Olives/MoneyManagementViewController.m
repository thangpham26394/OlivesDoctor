//
//  MoneyManagementViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/28/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MoneyManagementViewController.h"
#import "SWRevealViewController.h"
#import "MoneyDetailsViewController.h"
@interface MoneyManagementViewController ()
//@property (weak, nonatomic) IBOutlet LineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;

@property (weak, nonatomic) IBOutlet BarChartView *barChartView;



@end

@implementation MoneyManagementViewController
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Money management";
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Do any additional setup after loading the view, typically from a nib.

    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.menuButton setTarget:self.revealViewController];
        [self.menuButton setAction:@selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }

    NSArray * monthArray = @[@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov",@"Dec"];
    NSArray *unitSold = @[@"20.0", @"4.0", @"6.0",@"3.0", @"12.0", @"16.0",@"20.0", @"4.0", @"6.0",@"3.0", @"12.0", @"16.0"];
    self.barChartView.delegate = self;
    [self setChart:monthArray withValue:unitSold];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Chart View setting
-(void)setChart:(NSArray *)dataPoint withValue:(NSArray *) doubleValue{


    NSMutableArray <BarChartDataEntry *> *dataEntries = [[NSMutableArray alloc]init];
    for (int index =0; index<dataPoint.count; index++) {
        BarChartDataEntry * dataEntry = [[BarChartDataEntry alloc]initWithValue:[[doubleValue objectAtIndex:index] doubleValue]  xIndex:index];
        [dataEntries addObject:dataEntry];
    }

    BarChartDataSet *barCharDataSet = [[BarChartDataSet alloc]initWithYVals:dataEntries label:@"Money"];
    BarChartData *barCharData = [[BarChartData alloc]initWithXVals:dataPoint dataSet:barCharDataSet];
    self.barChartView.data = barCharData;
//    LineChartDataSet *lineChartDataSet = [[LineChartDataSet alloc]initWithYVals:dataEntries label:@"Glycemic"];
//    LineChartData *lineCharData = [[LineChartData alloc] initWithXVals:dataPoint dataSet:lineChartDataSet];
    self.barChartView.backgroundColor = [UIColor whiteColor];
    self.barChartView.descriptionText = @"";
    self.barChartView.xAxis.labelPosition = XAxisLabelPositionBottom;
    barCharDataSet.colors = @[[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
    [self.barChartView animateWithXAxisDuration:1.0 yAxisDuration:1.0 easingOption:ChartEasingOptionEaseInBounce];



}

-(void) chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry dataSetIndex:(NSInteger)dataSetIndex highlight:(ChartHighlight *)highlight{
    NSLog(@"hihihihi    %f %ld",entry.value,(long)entry.xIndex);
    [self performSegueWithIdentifier:@"viewDetailsMoney" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    MoneyDetailsViewController *moneyDetail = [segue destinationViewController];
    moneyDetail.month = @"July";
    moneyDetail.totalMoney = @"1000";
}


@end
