//
//  MedicalRecordExperimentNoteTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 8/7/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/experiment?Id="
#import "MedicalRecordExperimentNoteTableViewController.h"
#import "StringDoubleTableViewCell.h"
#import <CoreData/CoreData.h>


@interface MedicalRecordExperimentNoteTableViewController ()
@property(strong,nonatomic) NSMutableDictionary *info;
@property(strong,nonatomic) UIView *popupView;
@property(strong,nonatomic) UITextField *stringTextField;
@property(strong,nonatomic) UITextField *doubleTextField;
@property (weak, nonatomic) IBOutlet UITextField *experimentNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *buttonEdit;
@property (strong,nonatomic) NSDictionary *responseJSONData;


- (IBAction)buttonEditNameAction:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation MedicalRecordExperimentNoteTableViewController


#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)loadInfoFromCoredata{
    self.info = [[NSMutableDictionary alloc] init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ExperimentNotes"];
    NSMutableArray *experimentNoteObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *experimentNote;

    for (int index=0; index < experimentNoteObject.count; index++) {
        experimentNote = [experimentNoteObject objectAtIndex:index];
        if ([[experimentNote valueForKey:@"id"] isEqual:[NSString stringWithFormat:@"%@",self.experimentNoteID]]) {
            //get info of medical record in coredata which have same id with selected medical record
            self.experimentNameTextField.text = [experimentNote valueForKey:@"name"];
            NSString *infoString = [experimentNote valueForKey:@"info"];
            NSError *jsonError;
            NSData *objectData = [infoString dataUsingEncoding:NSUTF8StringEncoding];
            self.info = [NSJSONSerialization JSONObjectWithData:objectData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&jsonError];
        }
    }
    if (self.info ==nil) {
        self.info = [[NSMutableDictionary alloc] init];
    }
}





-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"Experiment Notes";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addInfo:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
    [self loadInfoFromCoredata];

}

-(IBAction)addInfo:(id)sender{
    // show popup view here
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;


    self.popupView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    self.popupView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];

    UIView *myView = [[UIView alloc]initWithFrame:CGRectMake(20, 150, screenWidth-40, 270)];
    myView.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0];
    myView.layer.cornerRadius = 10.0f;

    //create OK button
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth-40)/2,230, (screenWidth-40)/2, 40)];
    okButton.backgroundColor = [UIColor whiteColor];
    [okButton setTitle: @"OK" forState: UIControlStateNormal];
    [okButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    [okButton setTitleColor:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0] forState:UIControlStateNormal];

    UIBezierPath *maskPathOK = [UIBezierPath bezierPathWithRoundedRect:okButton.bounds byRoundingCorners:(UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayerOK = [[CAShapeLayer alloc] init];
    maskLayerOK.frame = self.popupView.bounds;
    maskLayerOK.path  = maskPathOK.CGPath;
    okButton.layer.mask = maskLayerOK;
    [okButton addTarget:self action:@selector(okButtonActionHightLight:) forControlEvents:UIControlEventTouchDown];
    [okButton addTarget:self action:@selector(okButtonActionNormal:) forControlEvents:UIControlEventTouchUpInside];



    //create cancel button
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0,230, (screenWidth-40)/2-1, 40)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton setTitle: @"Cancel" forState: UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0]];
    [cancelButton setTitleColor:[UIColor colorWithRed:17/255.0 green:122/255.0 blue:101/255.0 alpha:1.0] forState:UIControlStateNormal];

    UIBezierPath *maskPathCancel = [UIBezierPath bezierPathWithRoundedRect:cancelButton.bounds byRoundingCorners:(UIRectCornerBottomLeft) cornerRadii:CGSizeMake(10.0, 10.0)];

    CAShapeLayer *maskLayerCancel = [[CAShapeLayer alloc] init];
    maskLayerCancel.frame = self.popupView.bounds;
    maskLayerCancel.path  = maskPathCancel.CGPath;
    cancelButton.layer.mask = maskLayerCancel;
    [cancelButton addTarget:self action:@selector(cancelButtonActionHightLight:) forControlEvents:UIControlEventTouchDown];
    [cancelButton addTarget:self action:@selector(cancelButtonActionNormal:) forControlEvents:UIControlEventTouchUpInside];


    //Title Label
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,20, (screenWidth-40), 40)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0]];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleLabel setTextColor:[UIColor blackColor]];
    titleLabel.text = @"Add new experiment note";

    //top content View
    UIView *topContentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth-40, 229)];
    topContentView.backgroundColor = [UIColor whiteColor];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:topContentView.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.popupView.bounds;
    maskLayer.path  = maskPath.CGPath;
    topContentView.layer.mask = maskLayer;

    //text Field for string
    self.stringTextField = [[UITextField alloc]initWithFrame:CGRectMake(70, 100, screenWidth-130, 30)];
    [self.stringTextField  setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    self.stringTextField .layer.cornerRadius = 5.0f;


    //text Field For double
    self.doubleTextField = [[UITextField alloc]initWithFrame:CGRectMake(70, 140, screenWidth-130, 30)];
    [self.doubleTextField setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0]];
    self.doubleTextField.layer.cornerRadius = 5.0f;


    //name Label
    UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(10,100, 50, 30)];
    [nameLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15.0]];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [nameLabel setTextColor:[UIColor blackColor]];
    nameLabel.text = @"Name";

    //value Label
    UILabel *valueLabel = [[UILabel alloc]initWithFrame:CGRectMake(10,140, 50, 30)];
    [valueLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15.0]];
    valueLabel.textAlignment = NSTextAlignmentCenter;
    [valueLabel setTextColor:[UIColor blackColor]];
    valueLabel.text = @"Value";






    [topContentView addSubview:titleLabel];
    [topContentView addSubview:self.stringTextField ];
    [topContentView addSubview:self.doubleTextField];
    [topContentView addSubview:nameLabel];
    [topContentView addSubview:valueLabel];
    [myView addSubview:topContentView];
    [myView addSubview:okButton];
    [myView addSubview:cancelButton];

    [self.popupView addSubview:myView];
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self.popupView];

}
//action to change background color only
-(IBAction)okButtonActionHightLight:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor lightGrayColor];
}
-(IBAction)cancelButtonActionHightLight:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor lightGrayColor];
}

//action to call to add or update api
-(IBAction)okButtonActionNormal:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor whiteColor];
    NSLog(@"OK ACtion     %@",self.stringTextField.text);
}
//dissmiss popup view
-(IBAction)cancelButtonActionNormal:(id)sender{
    UIButton *button = (UIButton*)sender;
    button.backgroundColor = [UIColor whiteColor];
    NSLog(@"Cancel ACtion");
    [UIView animateWithDuration:0.5
                     animations:^{self.popupView .alpha = 0.0;}
                     completion:^(BOOL finished){ [self.popupView removeFromSuperview]; }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.buttonEdit.layer.cornerRadius = 5.0f;
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

    return self.info.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StringDoubleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"experimentNoteCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *key = [[self.info allKeys] objectAtIndex:indexPath.row];
    cell.stringTextField.text = [NSString stringWithFormat:@"%@",key];
    cell.doubleTextField.text = [NSString stringWithFormat:@"%@",[self.info objectForKey:key]];
    cell.stringTextField.userInteractionEnabled = NO;
    cell.doubleTextField.userInteractionEnabled = NO;

    cell.preservesSuperviewLayoutMargins = NO;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return  60;
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

- (IBAction)buttonEditNameAction:(id)sender {
}
@end
