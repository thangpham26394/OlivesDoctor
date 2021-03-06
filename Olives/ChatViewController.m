//
//  ChatViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/15/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net"
#define APIURL_CREATE_MESSAGE @"http://olive.azurewebsites.net/api/message"
#define API_MESSAGE_URL @"http://olive.azurewebsites.net/api/message/filter"
#define API_MESSAGE_SEEN_URL @"http://olive.azurewebsites.net/api/message/seen"

#import "ChatViewController.h"
#import "ChatDateTimeTableViewCell.h"
#import "ChatMessageSendTableViewCell.h"
#import "ChatMessageReceiveTableViewCell.h"
#import "SignalR.h"
#import <CoreData/CoreData.h>

@interface ChatViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *buttonSend;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property(strong,nonatomic) NSMutableArray *messageArray;
@property(assign,nonatomic) CGFloat noteLabelHeight;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property(strong,nonatomic) SRHubConnection *hubConnectionForChat;
@property(assign,nonatomic) BOOL connectToAPISuccess;
- (IBAction)sendAction:(id)sender;
@end

@implementation ChatViewController

#pragma mark - Coredata function
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

#pragma mark - Connect to API function

-(void)putSeenMessageDataToAPIWithPatientID:(NSString *) patientID{

    // create url
    NSURL *url = [NSURL URLWithString:API_MESSAGE_SEEN_URL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    sessionConfig.timeoutIntervalForRequest = 5.0;
    //    sessionConfig.timeoutIntervalForResource = 5.0;

    //NSURLSession *defaultSession = [NSURLSession sharedSession];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];


    //setup header and body for request
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setTimeoutInterval:10];

    //create JSON data to post to API
    NSDictionary *account = @{
                              @"Partner" :  patientID,
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsondata];

//    dispatch_semaphore_t    sem;
//    sem = dispatch_semaphore_create(0);

    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONData != nil) {
                                              }else{
                                              }

                                              //stop waiting after get response from API
//                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
//                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
//    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

}


-(void)getAllMessageFromAPIWithPatientID:(NSString *) patientID{

    // create url
    NSURL *url = [NSURL URLWithString:API_MESSAGE_URL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    sessionConfig.timeoutIntervalForRequest = 5.0;
    //    sessionConfig.timeoutIntervalForResource = 5.0;

    //NSURLSession *defaultSession = [NSURLSession sharedSession];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];


    //setup header and body for request
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setTimeoutInterval:10];

    //create JSON data to post to API
    NSDictionary *account = @{
                                    @"Sort":@"0",
                                    @"Partner":patientID
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsondata];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);

    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONData != nil) {
                                                  self.messageArray = [self.responseJSONData objectForKey:@"Messages"];

                                              }else{
                                              }

                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                              NSLog(@"\n\n\nError = %@",text);
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}


-(void)sendMessageToAPI:(NSString *)messageSent{

    // create url
    NSURL *url = [NSURL URLWithString:APIURL_CREATE_MESSAGE];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];


    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 5.0;
    // config session
    //NSURLSession *defaultSession = [NSURLSession sharedSession];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];


    //setup header and body for request
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *account = @{
                              @"Recipient" :  self.selectedPatientID,
                              @"Content" :messageSent,
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsondata];
    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);

    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONData != nil) {
                                                  self.connectToAPISuccess = YES;
                                              }else{
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self showAlertError:@"Can't connect to server"];
                                                  });
                                              }


                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              if (data ==nil) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self showAlertError:@"Can't connect to server"];
                                                  });
                                              }else{
                                                  NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                  NSLog(@"\n\n\nError = %@",text);
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self showAlertError:text];
                                                  });
                                              }

                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
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

//show alert message for error
-(void)showAlertError:(NSString *)errorString{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:errorString
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {}];
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - View delegate
- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    [self setupGestureRecognizerToDisMissKeyBoard];
    self.navigationController.topViewController.title = self.patientName;

}
-(void)viewDidAppear:(BOOL)animated{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"chatScreenLoaded"];
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedPatientID forKey:@"chattingPatient"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
    NSInteger  lastRowNumber = [self.tableView numberOfRowsInSection:0] - 1;
    if (lastRowNumber >=0) {
        NSIndexPath* ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"chatScreenLoaded"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self deregisterFromKeyboardNotifications];

    // Stop the connection for chat API
    [self.hubConnectionForChat stop];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.messageArray = [[NSMutableArray alloc]init];
    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    [self getAllMessageFromAPIWithPatientID:self.selectedPatientID];

    //reverse received Message
    NSMutableArray *reverseArray = [[NSMutableArray alloc] init];
    for (NSInteger index = self.messageArray.count-1; index >=0;index -- ) {
        [reverseArray addObject:[self.messageArray objectAtIndex:index]];
    }
    self.messageArray = reverseArray;
    [self.tableView reloadData];

    // Connect to the service
    id qs = @{
              @"Email": [doctor valueForKey:@"email"],
              @"Password": [doctor valueForKey:@"password"]
              };

    // Connect to the service chat
    self.hubConnectionForChat = [SRHubConnection connectionWithURLString:APIURL queryString:qs];
    // Create a proxy to the chat service
    SRHubProxy *notificationHubForChat = [self.hubConnectionForChat createHubProxy:@"NotificationHub"];
    [notificationHubForChat on:@"notifyMessage" perform:self selector:@selector(messageReceived:)];
    // Register for connection lifecycle events
    [self.hubConnectionForChat setStarted:^{
        NSLog(@"Connection Started");
    }];
    [self.hubConnectionForChat setReceived:^(NSString *message) {
        NSLog(@"Connection Recieved Data: %@",message);
    }];
    [self.hubConnectionForChat setConnectionSlow:^{
        NSLog(@"Connection Slow");
    }];
    [self.hubConnectionForChat setReconnecting:^{
        NSLog(@"Connection Reconnecting");
    }];
    [self.hubConnectionForChat setReconnected:^{
        NSLog(@"Connection Reconnected");
    }];
    [self.hubConnectionForChat setClosed:^{
        NSLog(@"Connection Closed");
    }];
    [self.hubConnectionForChat setError:^(NSError *error) {
        NSLog(@"Connection Error %@",error);
    }];
    // Start the connection for chat API
    [self.hubConnectionForChat start];



    // Do any additional setup after loading the view.
    self.buttonSend.layer.cornerRadius = 5.0f;
    self.messageTextView.layer.cornerRadius = 5.0f;
    self.contentViewHeight.constant = [[UIScreen mainScreen] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView reloadData];
    [self updateTableContentInset];
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
    return self.messageArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.noteLabelHeight + 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        NSDictionary *messageInfo = [self.messageArray objectAtIndex:indexPath.row];
        self.noteLabelHeight = [[messageInfo objectForKey:@"Content"] boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 140, CGFLOAT_MAX)
                                                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}
                                                                                   context:nil].size.height;

        NSString *notiTime = [messageInfo objectForKey:@"Created"];
        NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
        [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatterToLocal setDateFormat:@"HH:mm:ss"];

        NSDate *notiDate = [NSDate dateWithTimeIntervalSince1970:[notiTime doubleValue]/1000];

        NSString *broadCaster = [messageInfo objectForKey:@"Broadcaster"];


        if (![[NSString stringWithFormat:@"%@",broadCaster] isEqualToString:[NSString stringWithFormat:@"%@", self.selectedPatientID ]]){
            ChatMessageSendTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"sendCell" forIndexPath:indexPath];
            cell.messageLabel.text =[messageInfo objectForKey:@"Content"];
            cell.timeLabel.text = [dateFormatterToLocal stringFromDate:notiDate];
            return cell;
        }else{
            ChatMessageReceiveTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"receiveCell" forIndexPath:indexPath];
            cell.messageLabel.text = [messageInfo objectForKey:@"Content"];
            cell.timeLabel.text = [dateFormatterToLocal stringFromDate:notiDate];
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
- (void)messageReceived:(id)message{
    //do something with the message
    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&err];
    NSDictionary *messageDic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:kNilOptions
                                                                 error:nil];
    NSLog(@"%@",messageDic);
    NSString *broadcaster = [messageDic objectForKey:@"broadcaster"];
    NSString *content = [messageDic objectForKey:@"content"];
    NSString *created = [messageDic objectForKey:@"created"];

//    NSDateFormatter * dateFormatterToLocal = [[NSDateFormatter alloc] init];
//    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
//    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];
//
//    NSDate *notiDate = [NSDate dateWithTimeIntervalSince1970:[created doubleValue]/1000];

    //if broadcaster is current chatting patient
    if ([[NSString stringWithFormat:@"%@",self.selectedPatientID] isEqual: [NSString stringWithFormat:@"%@",broadcaster]]) {
        NSDictionary *cellContent = [NSDictionary dictionaryWithObjectsAndKeys:
                                     broadcaster,@"Broadcaster",
                                     content,@"Content",
                                     created,@"Created"
                                     , nil];
        self.messageTextView.text = @"";
        [self.messageArray addObject:cellContent];
        [self.tableView reloadData];
        NSInteger  lastRowNumber = [self.tableView numberOfRowsInSection:0] - 1;
        NSIndexPath* ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionNone animated:NO];
        [self putSeenMessageDataToAPIWithPatientID:self.selectedPatientID];

    }
}


- (IBAction)sendAction:(id)sender {
    NSString *message = self.messageTextView.text;
    NSString *trimmedString = [message stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    double time = [[NSDate date] timeIntervalSince1970 ]*1000;
    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];

    NSManagedObject *doctor = [doctorObject objectAtIndex:0];
    if (trimmedString!= nil  && ![trimmedString  isEqual: @""]) {
        self.connectToAPISuccess = NO;
        [self sendMessageToAPI:trimmedString];
        if (self.connectToAPISuccess) {
            NSDictionary *cellContent = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [doctor valueForKey:@"doctorID"],@"Broadcaster",
                                         trimmedString,@"Content",
                                         [NSString stringWithFormat:@"%f",time],@"Created"
                                         , nil];
            self.messageTextView.text = @"";
            [self.messageArray addObject:cellContent];
            [self.tableView reloadData];
            NSInteger  lastRowNumber = [self.tableView numberOfRowsInSection:0] - 1;
            NSIndexPath* ip = [NSIndexPath indexPathForRow:lastRowNumber inSection:0];
            [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionNone animated:NO];
        }
    }
}
@end
