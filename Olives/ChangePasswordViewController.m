//
//  ChangePasswordViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/27/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "EditProfileViewController.h"
#import <CoreData/CoreData.h>
@interface ChangePasswordViewController ()
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *doctorNewPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmNewPassword;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
- (IBAction)saveNewPassword:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *mistakeLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) UITextField *activeField;
@end

@implementation ChangePasswordViewController

- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}


- (IBAction)textFieldDidBeginEditing:(UITextField *)sender
{
    self.activeField = sender;
}

- (IBAction)textFieldDidEndEditing:(UITextField *)sender
{
    self.activeField = nil;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textfield {
    [self.activeField resignFirstResponder];
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];

}

- (void)viewWillDisappear:(BOOL)animated {

    [self deregisterFromKeyboardNotifications];

    [super viewWillDisappear:animated];
    
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
    //kbRect = [self.view convertRect:kbRect fromView:nil];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, self.saveButton.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.saveButton.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.saveButton.backgroundColor = [UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0];
    [self.saveButton.layer setCornerRadius:5.0f];
    [self setupGestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setupGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self.activeField resignFirstResponder];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"unwindToEditProfile"])
    {
        EditProfileViewController *editProfileViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        editProfileViewController.doctorNewPassword = self.doctorNewPasswordTextField.text;
    }
}


- (IBAction)saveNewPassword:(id)sender {
    //get the current doctor data

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    NSString *oldPassword = [doctor valueForKey:@"password"];
    if (![self.oldPasswordTextField.text isEqual: oldPassword]) {
        self.mistakeLabel.text = @"Your old password is invalid!";
    }else if (![self.doctorNewPasswordTextField.text isEqual:self.confirmNewPassword.text]){
        self.mistakeLabel.text = @"Confirm password invalid!";
    }else{
        self.mistakeLabel.text = @"";
    }

    //check if there is no error then send password infor to edit view controller
    if ([self.mistakeLabel.text isEqual:@""]) {
        [self performSegueWithIdentifier:@"unwindToEditProfile" sender:self];
    }
    

}
@end
