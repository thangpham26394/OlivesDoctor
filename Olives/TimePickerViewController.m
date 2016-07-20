//
//  TimePickerViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/12/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "TimePickerViewController.h"
#import "PatientTableViewCell.h"
#import "PatientsTableViewController.h"
@interface TimePickerViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *dateTimePickerFrom;
@property (weak, nonatomic) IBOutlet UIDatePicker *dateTimePickerTo;

@property (weak, nonatomic) IBOutlet UITextView *noteLabel;

-(IBAction)sendRequestButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UIButton *sendRequestButton;
@property (weak, nonatomic) IBOutlet UITableView *chosingPatientTableView;

@end

@implementation TimePickerViewController

#pragma mark - Configure scroll view

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {

        [textView resignFirstResponder];
        // Return FALSE so that the final '\n' character doesn't get added
        return NO;
    }
    // For any other character return TRUE so that the text gets added to the view
    return YES;
}

- (void)registerForKeyboardNotifications {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)deregisterFromKeyboardNotifications {

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    // If you are using Xcode 6 or iOS 7.0, you may need this line of code. There was a bug when you
    // rotated the device to landscape. It reported the keyboard as the wrong size as if it was still in portrait mode.
    kbRect = [self.view convertRect:kbRect fromView:nil];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, self.sendRequestButton.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.sendRequestButton.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

-(void) setupGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];

    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self.noteLabel resignFirstResponder];
}

#pragma mark - View delegate
- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    self.navigationController.topViewController.title = self.chosenDate;
    [self registerForKeyboardNotifications];

}

- (void)viewWillDisappear:(BOOL)animated {

    [self deregisterFromKeyboardNotifications];

    [super viewWillDisappear:animated];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.chosingPatientTableView.alwaysBounceVertical = NO;
//    self.chosingPatientTableView.scrollEnabled = YES;
    self.scrollView.bounces = NO;
    self.navigationController.navigationBar.translucent = NO;
    [self.chosingPatientTableView becomeFirstResponder];

    [self setupGestureRecognizer];
    self.contentViewHeight.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;

    self.dateTimePickerFrom.backgroundColor = [UIColor whiteColor];
    self.dateTimePickerFrom.layer.cornerRadius = 5.0f;
    self.dateTimePickerFrom.layer.masksToBounds = YES;

    self.dateTimePickerTo.backgroundColor = [UIColor whiteColor];
    self.dateTimePickerTo.layer.cornerRadius = 5.0f;
    self.dateTimePickerTo.layer.masksToBounds = YES;


    self.noteLabel.layer.cornerRadius = 5.0f;
    [self.noteLabel setShowsVerticalScrollIndicator:NO];

    //set time zone for date time picker to GMT
    [self.dateTimePickerFrom setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [self.dateTimePickerTo setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    //format initial date time
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setDateFormat:@"dd/MM/yyyy HH:mm:ss:SSS"];

    //formt initial date
    NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [dateFormat setLocale:[NSLocale systemLocale]];
    [dateFormat setDateFormat:@"dd/MM/yyyy"];
    NSString *initialDate = [dateFormat stringFromDate:[NSDate date]];

    //set up initial date time for dateTimePicker
    NSString *initialTime = [NSString stringWithFormat:@"%@  00:00:00:000",initialDate];
    NSDate * date = [formatter dateFromString:initialTime];

    [self.dateTimePickerFrom setDate:date];
    [self.dateTimePickerTo setDate:date];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Send request
-(IBAction)sendRequestButton:(id)sender{
    [self.noteLabel resignFirstResponder];
    [self showAlertView];
}



-(void)showAlertView{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Request Sent"
                                                               message:@"Your Request will be sent to your patient soon"
                                                               preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              //sent request to API here
                                                              NSLog(@"OK Action!");
                                                              [self.navigationController popViewControllerAnimated:YES];
                                                          }];


    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chosePatientCell" forIndexPath:indexPath];
    cell.nameLabel.text = @"PatientName";
    cell.phoneLabel.text = @"Phone: Patientphone";
    cell.address.text = @"Address: PatientAddress";

    // Configure the cell...

    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    [self performSegueWithIdentifier:@"showCurrentPatient" sender:self];

    [self.chosingPatientTableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showCurrentPatient"])
    {
        PatientsTableViewController *patientTableViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        patientTableViewController.isAppointmentViewDetailPatient = self.chosenDate;
    }
}


@end
