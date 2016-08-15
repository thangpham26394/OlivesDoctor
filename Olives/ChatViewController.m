//
//  ChatViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/15/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "ChatViewController.h"
#import "ChatDateTimeTableViewCell.h"
#import "ChatMessageSendTableViewCell.h"
#import "ChatMessageReceiveTableViewCell.h"

@interface ChatViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *buttonSend;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;

@end

@implementation ChatViewController
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
    if (!CGRectContainsPoint(aRect, self.bottomView.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.bottomView.frame animated:YES];
        self.scrollView.scrollEnabled = NO;
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


-(void) setupGestureRecognizerToDisMissKeyBoard {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureToDisMissKeyBoard:)];
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)handleTapGestureToDisMissKeyBoard:(UIPanGestureRecognizer *)recognizer{
    [self.messageTextView resignFirstResponder];
}


#pragma mark - View delegate
- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    [self setupGestureRecognizerToDisMissKeyBoard];
}

- (void)viewWillDisappear:(BOOL)animated {

    [self deregisterFromKeyboardNotifications];

    [super viewWillDisappear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.buttonSend.layer.cornerRadius = 5.0f;
    self.messageTextView.layer.cornerRadius = 5.0f;
    self.contentViewHeight.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;
//    [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
    [self updateTableContentInset];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)updateTableContentInset {
    NSInteger numRows = [self tableView:self.tableView numberOfRowsInSection:0];
    CGFloat contentInsetTop = self.tableView.bounds.size.height;
    for (NSInteger i = 0; i < numRows; i++) {
        contentInsetTop -= [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        if (contentInsetTop <= 0) {
            contentInsetTop = 0;
            break;
        }
    }
    self.tableView.contentInset = UIEdgeInsetsMake(contentInsetTop, 0, 0, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;//self.notifictionDataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row ==0) {
        return 30;
    }else if (indexPath.row == 1){
        return 100;
    }else{
        return 100;
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row ==0) {
        ChatDateTimeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"dateTimeCell" forIndexPath:indexPath];
        return cell;
    }else if (indexPath.row%2 == 1){
        ChatMessageSendTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"receiveCell" forIndexPath:indexPath];
        cell.messageLabel.text = @"Hi! are you busy right now?";
        return cell;
    }else{
        ChatMessageReceiveTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"sendCell" forIndexPath:indexPath];
        cell.messageLabel.text = @"Not really! Is there anything i can help !?";
        return cell;
    }

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
