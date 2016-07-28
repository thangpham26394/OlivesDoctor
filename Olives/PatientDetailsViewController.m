//
//  PatientDetailsViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 6/25/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "PatientDetailsViewController.h"
#import <CoreData/CoreData.h>
@interface PatientDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;
@property (weak, nonatomic) IBOutlet UITableView *importantInfoTableView;
@property (weak, nonatomic) IBOutlet UILabel *patientName;
@property (weak, nonatomic) IBOutlet UILabel *patientPhone;
@property (weak, nonatomic) IBOutlet UILabel *patientAddress;
@property (weak, nonatomic) IBOutlet UILabel *patientEmail;


@end

@implementation PatientDetailsViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Patient Details";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"TTTTTTTTTTTTTTTTTTTTTT        %@",self.selectedPatientID);
    //get patient infor from coredata with sent id
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PatientInfo"];
    NSMutableArray *patientObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *patient;
    for (int index = 0; index<patientObject.count; index++) {
        patient = [patientObject objectAtIndex:index];
        if ([[patient valueForKey:@"patientId"] isEqual:self.selectedPatientID]) {
            break;
        }
    }
    self.avatarImage.image = [UIImage imageWithData:[patient valueForKey:@"photo"]];
    self.patientName.text = [NSString stringWithFormat:@"%@ %@",[patient valueForKey:@"firstName"],[patient valueForKey:@"lastName"]];
    self.patientPhone.text = [patient valueForKey:@"phone"];
    self.patientAddress.text = [patient valueForKey:@"address"];
    self.patientEmail.text = [patient valueForKey:@"email"];

    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width / 2;
    self.avatarImage.clipsToBounds = YES;
    self.importantInfoTableView.layer.cornerRadius = 5;
    self.importantInfoTableView.clipsToBounds = YES;
    self.sendMessageButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:153/255.0 blue:153/255.0 alpha:1.0];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)addInfo:(id)sender{
    NSLog(@"important info add");
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 10;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"importantInfoCell" ];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:@"importantInfoCell"];

    }
    // Configure the cell...
    cell.textLabel.text = @"Diabetes";
//    cell.detailTextLabel.text = @"details";

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    // Configure the cell...

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    [self performSegueWithIdentifier:@"showChartView" sender:self];

    [self.importantInfoTableView deselectRowAtIndexPath:indexPath animated:YES];
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
