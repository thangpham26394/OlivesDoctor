//
//  MedicalNoteTableViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/31/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/record"
#import "MedicalNoteTableViewController.h"
#import "ShowDetailInfoMedicalRecordTableViewController.h"
#import "MedicalRecordPresctiptionTableViewController.h"
#import "MedicalRecordNoteDetailTableViewController.h"
#import "MedicalRecordImagesCollectionViewController.h"
#import "ExperimentNoteGeneralTableViewController.h"
#import <CoreData/CoreData.h>


@interface MedicalNoteTableViewController ()
@property (weak, nonatomic) IBOutlet UITextView *noteView;
@property(assign,nonatomic) CGFloat noteViewHeight;
@property(strong,nonatomic) NSString* medicalNote;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *medicalRecordNameLabel;

@end

@implementation MedicalNoteTableViewController

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)reloadDataFromCoreData{
    //get the newest medical record data which have just saved to coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
    NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalRecord;

    for (int index =0; index<medicalRecordObject.count; index++) {
        //get each patient in coredata
        medicalRecord = [medicalRecordObject objectAtIndex:index];
        //get medical record category
        NSFetchRequest *fetchRequestCategory = [[NSFetchRequest alloc] initWithEntityName:@"MedicalCategories"];
        NSMutableArray *medicalCategoryObject = [[context executeFetchRequest:fetchRequestCategory error:nil] mutableCopy];
        NSManagedObject *medicalCategory;
        NSDictionary *medicalCategoryDic;

        for (int i=0; i<medicalCategoryObject.count; i++) {
            medicalCategory = [medicalCategoryObject objectAtIndex:i];
            //check if the current medical category id is equal with medical record id
            if ([[medicalCategory valueForKey:@"medicalCategoryID"] isEqual:[medicalRecord valueForKey:@"categoryID" ]]) {
                medicalCategoryDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [medicalCategory valueForKey:@"medicalCategoryID" ],@"Id",
                                      [medicalCategory valueForKey:@"name" ],@"Name",
                                      nil];
            }

            NSDictionary *medicalRecordDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [medicalRecord valueForKey:@"medicalRecordID" ],@"Id",
                                              [medicalRecord valueForKey:@"ownerID" ],@"Owner",
                                              [medicalRecord valueForKey:@"creatorID" ],@"Creator",
                                              medicalCategoryDic,@"Category",
                                              [medicalRecord valueForKey:@"info" ],@"Info",
                                              [medicalRecord valueForKey:@"time" ],@"Time",
                                              [medicalRecord valueForKey:@"createdDate" ],@"Created",
                                              [medicalRecord valueForKey:@"lastModified" ],@"LastModified",
                                              nil];

            if ([[medicalRecord valueForKey:@"medicalRecordID" ] isEqual:[NSString stringWithFormat:@"%@",[self.medicalRecordDic objectForKey:@"Id"]]]) {
                self.medicalRecordDic = medicalRecordDic;
            }
            
        }
        
    }

}

#pragma mark handle api connection
-(void)editMedicalRecordToAPI{
    
}



#pragma mark view controller

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupGestureRecognizer];
    NSLog(@"%@",self.medicalRecordDic);


    NSString *time = [self.medicalRecordDic objectForKey:@"Time"];


    NSDateFormatter * dateFormatterToLocal= [[NSDateFormatter alloc] init];
    [dateFormatterToLocal setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatterToLocal setDateFormat:@"MM/dd/yyyy"];

    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]/1000];

    NSDate *timeDateLocal = [dateFormatterToLocal dateFromString:[dateFormatterToLocal stringFromDate:timeDate]];


    self.timeLabel.text = [NSString stringWithFormat:@"%@",[dateFormatterToLocal stringFromDate:timeDateLocal]];
    self.medicalRecordNameLabel.text = @"name here";
 }


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadDataFromCoreData];
    self.navigationController.topViewController.title=@"Details";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setupGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UIPanGestureRecognizer *)recognizer{
    [self.noteView resignFirstResponder];
}



#pragma mark - Table view data source

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if (indexPath.section ==3) {
//        return self.noteViewHeight + 65;
//    }else{
//        return 45;
//    }
//}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    NSLog(@"FFFFFFFFFF %ld",(long)section);
//    if (section ==0) {
//        return 1;
//    }else{
//        return 2;
//    }
//
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 5) {
    }
}



//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell;
//    if (indexPath.section ==0) {
//        cell = [tableView dequeueReusableCellWithIdentifier:@"medicalNoteCell" forIndexPath:indexPath];
//        cell.textLabel.text = @"medical note cell";
//    }else{
//        cell = [tableView dequeueReusableCellWithIdentifier:@"detailInfoCell" forIndexPath:indexPath];
//        cell.textLabel.text = @"detail info cell";
//    }

    
//    // Configure the cell...
//    
//    return cell;
//}


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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //this view is use for add new medical record or not

        if ([[segue identifier] isEqualToString:@"showDetailInformation"])
        {
            ShowDetailInfoMedicalRecordTableViewController *medicalRecordDetail = [segue destinationViewController];
            medicalRecordDetail.selectedMedicalRecord = self.medicalRecordDic;
        }
        if ([[segue identifier] isEqualToString:@"medicalRecordPrescription"])
        {
            MedicalRecordPresctiptionTableViewController *medicalRecordPrescriptionDetail = [segue destinationViewController];
            medicalRecordPrescriptionDetail.medicalRecordID = [self.medicalRecordDic objectForKey:@"Id"];
        }
        if ([[segue identifier] isEqualToString:@"medicalRecordNoteDetail"])
        {
            MedicalRecordNoteDetailTableViewController *medicalRecordNoteDetail = [segue destinationViewController];
            medicalRecordNoteDetail.selectedMedicalRecord = self.medicalRecordDic;
        }
        if ([[segue identifier] isEqualToString:@"showMedicalRecordImages"])
        {
            MedicalRecordImagesCollectionViewController *medicalRecordImage= [segue destinationViewController];
            medicalRecordImage.medicalRecordID = [self.medicalRecordDic objectForKey:@"Id"];

        }
    if ([[segue identifier] isEqualToString:@"showExperimentNote"])
    {
        ExperimentNoteGeneralTableViewController *medicalRecordExperimentNote= [segue destinationViewController];
        medicalRecordExperimentNote.medicalRecordID = [self.medicalRecordDic objectForKey:@"Id"];

    }

}


@end
