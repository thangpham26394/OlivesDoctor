//
//  PrescriptionViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/21/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "PrescriptionViewController.h"

@interface PrescriptionViewController ()
@property (weak, nonatomic) IBOutlet UITableView *currentTableView;
@property (weak, nonatomic) IBOutlet UITableView *historyTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentController;
- (IBAction)changeSegment:(id)sender;

@end

@implementation PrescriptionViewController
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Prescription";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.currentTableView setHidden:NO];
    [self.historyTableView setHidden:YES];
    self.currentTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.historyTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)addInfo:(id)sender{
    NSLog(@"add Prescription");
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (self.segmentController.selectedSegmentIndex ==0) {
        cell = [self.currentTableView dequeueReusableCellWithIdentifier:@"currentCell" forIndexPath:indexPath];
        cell.textLabel.text = @"Current prescription";
    }else{
        cell = [self.historyTableView dequeueReusableCellWithIdentifier:@"historyCell" forIndexPath:indexPath];
        cell.textLabel.text = @"History prescription";
    }


    // Configure the cell...
    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"prescriptionShowDetail" sender:self];
    if (self.segmentController.selectedSegmentIndex ==0) {
        [self.currentTableView deselectRowAtIndexPath:indexPath animated:YES];
    }


}
- (IBAction)changeSegment:(id)sender {
    switch (self.segmentController.selectedSegmentIndex)
    {
        case 0:
            [self.currentTableView setHidden:NO];
            [self.historyTableView setHidden:YES];
            [self.currentTableView reloadData];
            [self.historyTableView reloadData];
            break;
        case 1:
            [self.historyTableView setHidden:NO];
            [self.currentTableView setHidden:YES];
            [self.currentTableView reloadData];
            [self.historyTableView reloadData];
            break;
        default:
            break;
    }
}
@end
