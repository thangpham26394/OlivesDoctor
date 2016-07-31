//
//  ImportantInfoChartViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/19/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "ImportantInfoChartViewController.h"
#import "Olives-Bridging-Header.h"
@interface ImportantInfoChartViewController ()
@property (weak, nonatomic) IBOutlet LineChartView *lineChartView;



@end

@implementation ImportantInfoChartViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    [self.lineChartView setHidden:NO];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray * monthArray = @[@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun"];
    NSArray *unitSold = @[@"20.0", @"4.0", @"6.0",@"3.0", @"12.0", @"16.0"];
    [self setChart:monthArray withValue:unitSold];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Chart View setting
-(void)setChart:(NSArray *)dataPoint withValue:(NSArray *) doubleValue{
    NSMutableArray <ChartDataEntry *> *dataEntries = [[NSMutableArray alloc]init];
    for (int i =0; i<dataPoint.count; i++) {
        ChartDataEntry *dataEntry = [[ChartDataEntry alloc]initWithValue:[[doubleValue objectAtIndex:i] doubleValue]  xIndex:i];
        [dataEntries addObject:dataEntry];
    }


    LineChartDataSet *lineChartDataSet = [[LineChartDataSet alloc]initWithYVals:dataEntries label:@"Glycemic"];
    LineChartData *lineCharData = [[LineChartData alloc] initWithXVals:dataPoint dataSet:lineChartDataSet];
    self.lineChartView.backgroundColor = [UIColor whiteColor];
    self.lineChartView.descriptionText = @"Diabetes statistic";
    self.lineChartView.xAxis.labelPosition = XAxisLabelPositionBottom;
    ChartLimitLine * limit = [[ChartLimitLine alloc]initWithLimit:10.0 label:@"Normal"];

    limit.lineColor = [UIColor blueColor];
    [self.lineChartView.rightAxis addLimitLine:limit];
    lineChartDataSet.colors = @[[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
    NSMutableArray *colorArray = [[NSMutableArray alloc]init];
    for (int i=0;i<doubleValue.count; i++) {
        if ([[doubleValue objectAtIndex:i] doubleValue] <=10.0) {
            [colorArray addObject:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
        }else{
            [colorArray addObject:[UIColor redColor]];
        }
    }
    lineChartDataSet.circleColors = [colorArray copy];
    [self.lineChartView animateWithXAxisDuration:2.0 yAxisDuration:2.0 easingOption:ChartEasingOptionEaseInSine];
    lineChartDataSet.valueTextColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];
    self.lineChartView.data = lineCharData;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
