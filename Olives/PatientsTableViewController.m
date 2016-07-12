//
//  PatientsTableViewController.m
//  SLideViewDemo
//
//  Created by Tony Tony Chopper on 5/26/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "PatientsTableViewController.h"
#import "SWRevealViewController.h"
#import "PatientTableViewCell.h"

@interface PatientsTableViewController ()
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (strong,nonatomic) NSArray *patientArray;
@property (assign,nonatomic) BOOL isAddNewAppointment;


-(IBAction)cancel:(id)sender;
@end

@implementation PatientsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isAddNewAppointment = NO;
    //setup barbutton
    UIBarButtonItem *leftBarButton ;
    self.patientArray = [NSArray arrayWithObjects: @"Monkey.D Luffy", @"Tony Tony Chopper",@"Tony Tony Chopper Chopper",nil];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setShowsVerticalScrollIndicator:NO];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"homescreen2.jpg"]];

    self.tableView.backgroundView = imageView;

    //set up menu button if not isAppointmentViewDetailPatient
    if ([self.isAppointmentViewDetailPatient  isEqual: @""] || self.isAppointmentViewDetailPatient == nil) {


        SWRevealViewController *revealViewController = self.revealViewController;

        if (revealViewController) {
            leftBarButton = [[UIBarButtonItem alloc]
                             initWithImage:[UIImage imageNamed:@"menu.png"]
                             style:UIBarButtonItemStylePlain
                             target:self.revealViewController
                             action:@selector(revealToggle:)];
            self.navigationItem.leftBarButtonItem = leftBarButton;

//            [self.menuButton setTarget:self.revealViewController];
//            [self.menuButton setAction:@selector(revealToggle:)];
            [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
        }
    }else{
        // when user choose add new appointment
        self.isAddNewAppointment = YES;
        leftBarButton = [[UIBarButtonItem alloc]
                         initWithTitle:@"Cancel"
                         style:UIBarButtonItemStylePlain
                         target:self
                         action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = leftBarButton;
    }

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)cancel:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.patientArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"patientCell" forIndexPath:indexPath];
    cell.nameLabel.text = self.patientArray[indexPath.row];
    
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    if (!self.isAddNewAppointment) {
        // if the view current state is not for add new appointment
        [self performSegueWithIdentifier:@"showDetailPatient" sender:self];
    }else{
        //if the view current state is for add new appointment
        
    }

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
