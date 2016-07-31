//
//  MoneyDetailsViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/29/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MoneyDetailsViewController.h"

@interface MoneyDetailsViewController ()
@property (weak, nonatomic) IBOutlet PieChartView *pieChartView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;

@end

@implementation MoneyDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.headerLabel.text = [NSString stringWithFormat:@"Money report for month %@",self.month];
    NSArray * serviceArray = @[@"SV1", @"SV2", @"SV3", @"SV4", @"SV5"];
    NSArray *moneyForService = @[@"200", @"40", @"60",@"30", @"120"];
    [self setChart:serviceArray withValue:moneyForService];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Chart View setting
-(void)setChart:(NSArray *)dataPoint withValue:(NSArray *) doubleValue{


    NSMutableArray <ChartDataEntry *> *dataEntries = [[NSMutableArray alloc]init];
    for (int index =0; index<dataPoint.count; index++) {
        ChartDataEntry * dataEntry = [[ChartDataEntry alloc]initWithValue:[[doubleValue objectAtIndex:index] doubleValue]  xIndex:index];
        [dataEntries addObject:dataEntry];
    }

    PieChartDataSet *pieCharDataSet = [[PieChartDataSet alloc]initWithYVals:dataEntries label:@"Money"];
    PieChartData *pieCharData = [[PieChartData alloc]initWithXVals:dataPoint dataSet:pieCharDataSet];

    NSMutableArray *color = [[NSMutableArray alloc]init];
    for (int index =0; index < dataPoint.count; index ++) {

        int red = arc4random_uniform(256);
        int green = arc4random_uniform(256);
        int blue = arc4random_uniform(256);
        [color addObject:[UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0]];
    }
    pieCharDataSet.colors = color;
    self.pieChartView.data = pieCharData;
    self.pieChartView.backgroundColor = [UIColor whiteColor];
    self.pieChartView.descriptionText = @"";



    
    
    
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
