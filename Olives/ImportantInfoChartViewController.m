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
@property(strong,nonatomic)NSString *chartName;


@end

@implementation ImportantInfoChartViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    [self.lineChartView setHidden:NO];
    self.chartName = [[self.displayDataDic allKeys] objectAtIndex:0];
    NSArray *displayData = [self.displayDataDic objectForKey:self.chartName];
    NSMutableArray *timeArray = [[NSMutableArray alloc]init];
    NSMutableArray *valueArray = [[NSMutableArray alloc]init];
    //get infor from self.displayData
    for (int index = 0; index<displayData.count; index++) {
        NSDictionary *currentDic = displayData[index];
        NSString *key = [[currentDic allKeys] objectAtIndex:0];
        NSString *value = [currentDic objectForKey:key];
        [timeArray addObject:value];
        [valueArray addObject:key];
    }


    [self setChart:timeArray withValue:valueArray];
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


    LineChartDataSet *lineChartDataSet = [[LineChartDataSet alloc]initWithYVals:dataEntries label:self.chartName];
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
