//
//  AppDelegate.m
//  Olives
//
//  Created by Tony Tony Chopper on 5/23/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net"
//#define ROOTVIEW [[[UIApplication sharedApplication] keyWindow] rootViewController]
#import "AppDelegate.h"
#import "SignalR.h"
#import "HomeViewController.h"
@interface AppDelegate ()
@property(strong,nonatomic) UIView *popupNotification;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    //[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"imagesbar.jpeg"] forBarMetrics:UIBarMetricsDefault];
    UIStoryboard *storyboard = self.window.rootViewController.storyboard;
    UIViewController *rootViewController ;
    //Check login status to set initial view

    //check if app is first time lauching
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        //first time
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"loginStatus"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
    }else //after first time
    {

        //if the current account is still login
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"loginStatus"]) {
            rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeView"];
        }else{
            rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
        }
    }


    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];

    //refresh nsuserdefault incase app shutdown incorrectly
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"chatScreenLoaded"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"homeScreenLoaded"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }


    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    if (doctorObject.count>0) {
        NSManagedObject *doctor = [doctorObject objectAtIndex:0];
        // Connect to the service
        id qs = @{
                  @"Email": [doctor valueForKey:@"email"],
                  @"Password": [doctor valueForKey:@"password"]
                  };
        SRHubConnection *hubConnection = [SRHubConnection connectionWithURLString:APIURL queryString:qs];
        // Create a proxy to the chat service
        SRHubProxy *notificationHub = [hubConnection createHubProxy:@"NotificationHub"];

        [notificationHub on:@"broadcastNotification" perform:self selector:@selector(notificationReceived:)];

        // Register for connection lifecycle events
        [hubConnection setStarted:^{
            NSLog(@"Connection Started");
        }];

        [hubConnection setReceived:^(NSString *message) {
            NSLog(@"Connection Recieved Data: %@",message);
        }];

        [hubConnection setConnectionSlow:^{
            NSLog(@"Connection Slow");
        }];
        [hubConnection setReconnecting:^{
            NSLog(@"Connection Reconnecting");
        }];
        [hubConnection setReconnected:^{
            NSLog(@"Connection Reconnected");
        }];
        [hubConnection setClosed:^{
            NSLog(@"Connection Closed");
        }];
        [hubConnection setError:^(NSError *error) {
            NSLog(@"Connection Error %@",error);
        }];
        // Start the connection
        [hubConnection start];




        // Connect to the service chat
        SRHubConnection *hubConnectionForChat = [SRHubConnection connectionWithURLString:APIURL queryString:qs];
        // Create a proxy to the chat service
        SRHubProxy *notificationHubForChat = [hubConnectionForChat createHubProxy:@"NotificationHub"];
        [notificationHubForChat on:@"notifyMessage" perform:self selector:@selector(messageReceived:)];
        // Register for connection lifecycle events
        [hubConnectionForChat setStarted:^{
            NSLog(@"Connection Started");
        }];
        [hubConnectionForChat setReceived:^(NSString *message) {
            NSLog(@"Connection Recieved Data: %@",message);
        }];
        [hubConnectionForChat setConnectionSlow:^{
            NSLog(@"Connection Slow");
        }];
        [hubConnectionForChat setReconnecting:^{
            NSLog(@"Connection Reconnecting");
        }];
        [hubConnectionForChat setReconnected:^{
            NSLog(@"Connection Reconnected");
        }];
        [hubConnectionForChat setClosed:^{
            NSLog(@"Connection Closed");
        }];
        [hubConnectionForChat setError:^(NSError *error) {
            NSLog(@"Connection Error %@",error);
        }];
        // Start the connection for chat API
        [hubConnectionForChat start];

    }


    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){

        [application registerUserNotificationSettings:[UIUserNotificationSettings
                                                       settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|
                                                       UIUserNotificationTypeSound categories:nil]];
    }

    UILocalNotification *locationNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (locationNotification) {
        // Set icon badge number to zero
        application.applicationIconBadgeNumber = 0;
    }

    return YES;
}


- (void)messageReceived:(id)message
{


    //do something with the message
    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&err];
    NSDictionary *messageDic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:kNilOptions
                                                                 error:nil];
    NSLog(@"%@",messageDic);
    NSString *broadcaster = [messageDic objectForKey:@"broadcaster"];
    //if user is current in chat screen
    NSString *chattingPatientID;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"chatScreenLoaded"]) {
        chattingPatientID = [[NSUserDefaults standardUserDefaults] objectForKey:@"chattingPatient"];

    }
    if (![[NSString stringWithFormat:@"%@",chattingPatientID] isEqual: [NSString stringWithFormat:@"%@",broadcaster]]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        notification.alertBody = [messageDic objectForKey:@"content"];
        notification.alertAction = @"Show me";
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;

        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }

}




- (void)notificationReceived:(id)message
{
    //do something with the message
    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&err];
    NSDictionary *messageDic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                 options:kNilOptions
                                                                   error:nil];
    NSLog(@"%@",messageDic);
    

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    notification.alertBody = [messageDic objectForKey:@"Message"];
    notification.alertAction = @"Show me";
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;

    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    self.popupNotification = [[UIView alloc]initWithFrame:CGRectMake(0, -64, screenWidth, 64)];
//    self.popupNotification.backgroundColor = [UIColor colorWithRed:0/255.0 green: 0/255.0 blue:0/255.0 alpha:0.1  ];

    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        self.popupNotification.backgroundColor = [UIColor clearColor];

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.popupNotification.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [self.popupNotification addSubview:blurEffectView];
    } else {
        self.popupNotification.backgroundColor = [UIColor blackColor];
    }

    //reload home screen if needed
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"homeScreenLoaded"]) {
        UIStoryboard *storyboard = self.window.rootViewController.storyboard;
        //move to home view
        UIViewController *homeController ;
        homeController = [storyboard instantiateViewControllerWithIdentifier:@"HomeView"];
        AppDelegate *myAppDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        myAppDelegate.window.rootViewController = homeController;
        [myAppDelegate.window makeKeyAndVisible];
    }



    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self.popupNotification];
    //create OK button
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 64)];
    okButton.backgroundColor =[UIColor clearColor ];
    [okButton setTitle: notification.alertBody forState: UIControlStateNormal];
    [okButton.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    [okButton.titleLabel setNumberOfLines:1];
    [okButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    [okButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [okButton addTarget:self action:@selector(okButtonActionHightLight:) forControlEvents:UIControlEventTouchDown];
    [okButton addTarget:self action:@selector(okButtonActionNormal:) forControlEvents:UIControlEventTouchUpInside];
    [self.popupNotification addSubview:okButton];



    
    //show popup notification view
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self.popupNotification setFrame:CGRectMake(0, 0, screenWidth, 64)]; }
                     completion:^(BOOL finished){
                            
                          }];
    NSTimeInterval timeInterval = 5.0f; // how long your view will last before hiding
    [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(hideView) userInfo:nil repeats:NO];


    application.applicationIconBadgeNumber = 0;

}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.SelfLearning.Olives" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Olives" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Olives.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

//action to change background color only
-(IBAction)okButtonActionHightLight:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor clearColor];
}

//action to call to add or update api
-(IBAction)okButtonActionNormal:(id)sender{
    UIButton *button = (UIButton*)sender;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    button.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.25
                          delay:0 options:UIViewAnimationOptionTransitionCurlUp
                     animations:^{[self.popupNotification setFrame:CGRectMake(0, -64, screenWidth, 64)];}
                     completion:^(BOOL finished){
                     }];

    UIStoryboard *storyboard = self.window.rootViewController.storyboard;
    //move to home view
    UIViewController *homeController ;
    homeController = [storyboard instantiateViewControllerWithIdentifier:@"HomeView"];
    AppDelegate *myAppDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    myAppDelegate.window.rootViewController = homeController;

    [myAppDelegate.window makeKeyAndVisible];

}
-(void) hideView {

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    [UIView animateWithDuration:0.25
                          delay:0 options:UIViewAnimationOptionTransitionCurlUp
                     animations:^{[self.popupNotification setFrame:CGRectMake(0, -64, screenWidth, 64)];}
                     completion:^(BOOL finished){
                     }];
}
@end
