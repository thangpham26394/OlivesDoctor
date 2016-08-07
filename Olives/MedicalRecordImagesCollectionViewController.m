//
//  MedicalRecordImagesCollectionViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/17/16.
//  Copyright © 2016 Thang. All rights reserved.
//
#define APIURL @"http://olive.azurewebsites.net/api/medical/image/filter"
#define APIURLUPLOAD @"http://olive.azurewebsites.net/api/medical/image"
#define ACCEPTLIMITSIZE 4000

#import "MedicalRecordImagesCollectionViewController.h"
#import "MedicalRecordImageShowViewController.h"
#import "MedicalRecordListCollectionReusableView.h"
#import <CoreData/CoreData.h>



@interface MedicalRecordImagesCollectionViewController ()
@property(strong,nonatomic) NSMutableArray *medicalRecordImages;
@property(strong,nonatomic) NSString *partner;
@property (strong,nonatomic) NSDictionary *responseJSONData;
@property (strong,nonatomic) UIImage *selectedImage;
@end

@implementation MedicalRecordImagesCollectionViewController

static NSString * const reuseIdentifier = @"medicalRecordImage";

#pragma mark - Handle Coredata
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

-(void)loadPartnerFromCoredata{

    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MedicalRecord"];
    NSMutableArray *medicalRecordObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *medicalRecord;

    for (int index=0; index < medicalRecordObject.count; index++) {
        medicalRecord = [medicalRecordObject objectAtIndex:index];
        if ([[medicalRecord valueForKey:@"medicalRecordID"] isEqual:[NSString stringWithFormat:@"%@",self.medicalRecordID]]) {
            self.partner = [medicalRecord valueForKey:@"ownerID"];
        }
    }

}


#pragma mark - Connect to API function

//resize image func
- (UIImage *)compressForUpload:(UIImage *)original scale:(CGFloat)scale
{
    // Calculate new size given scale factor.
    CGSize originalSize = original.size;
    CGSize newSize = CGSizeMake(originalSize.width * scale, originalSize.height * scale);

    // Scale the original image to match the new size.
    UIGraphicsBeginImageContext(newSize);
    [original drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage* compressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return compressedImage;
}

-(void)uploadMedicalRecordImageToAPI:(UIImage *)pickedImage{
    // create url
    NSURL *url = [NSURL URLWithString:APIURLUPLOAD];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    //create request
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

    //get doctor email and password from coredata
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"DoctorInfo"];
    NSMutableArray *doctorObject = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    NSManagedObject *doctor = [doctorObject objectAtIndex:0];

    NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
    //setup header and body for request
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:[doctor valueForKey:@"email"] forHTTPHeaderField:@"Email"];
    [urlRequest setValue:[doctor valueForKey:@"password"]  forHTTPHeaderField:@"Password"];
    [urlRequest setValue:@"en-US" forHTTPHeaderField:@"Accept-Language"];

    //set up content type for request <content both params and image data>
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
    [urlRequest setValue:contentType forHTTPHeaderField: @"Content-Type"];



    // config body
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"MedicalRecord\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", self.medicalRecordID] dataUsingEncoding:NSUTF8StringEncoding]];


    // add image data
    NSData *imgData = UIImagePNGRepresentation(pickedImage);
    NSLog(@"before-------------%lu",imgData.length /1024);

    UIImage *resizedImage = pickedImage;
    while (imgData.length/1024 > ACCEPTLIMITSIZE) {

        resizedImage = [self compressForUpload:resizedImage scale:0.9];
        imgData = UIImagePNGRepresentation(resizedImage);
    }


    NSLog(@"after-------------%lu",imgData.length /1024);


    //create a name for image with the current time in milisec
    NSDateFormatter *dateFormaterToUTC = [[NSDateFormatter alloc] init];
    dateFormaterToUTC.timeStyle = NSDateFormatterNoStyle;
    dateFormaterToUTC.dateFormat = @"MM/dd/yyyy HH:mm:ss:SSS";


    if (imgData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"File\"; filename=\"%@\"\r\n",[dateFormaterToUTC stringFromDate:[NSDate date]]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imgData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    [urlRequest setHTTPBody:body];



//    [urlRequest setHTTPBody:jsondata];

    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);

    NSURLSessionTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                  {
                                      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                      if((long)[httpResponse statusCode] == 200  && error ==nil)
                                      {
                                          NSError *parsJSONError = nil;
                                          self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                          if (self.responseJSONData != nil) {
                                              //                                                  [self saveMedicalRecordToCoreData];
                                          }else{

                                          }
                                          //stop waiting after get response from API
                                          dispatch_semaphore_signal(sem);
                                      }
                                      else{
                                          NSError *parsJSONError = nil;
                                          if (data ==nil) {
                                              UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Internet Error"
                                                                                                             message:nil
                                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                                              UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                 style:UIAlertActionStyleDefault
                                                                                               handler:^(UIAlertAction * action) {}];
                                              [alert addAction:OKAction];
                                              [self presentViewController:alert animated:YES completion:nil];
                                              dispatch_semaphore_signal(sem);

                                              return;
                                          }
                                          NSDictionary *errorDic = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                          NSArray *errorArray = [errorDic objectForKey:@"Errors"];
                                          //                                              NSLog(@"\n\n\nError = %@",[errorArray objectAtIndex:0]);

                                          UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                                         message:[errorArray objectAtIndex:0]
                                                                                                  preferredStyle:UIAlertControllerStyleAlert];

                                          UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                             style:UIAlertActionStyleDefault
                                                                                           handler:^(UIAlertAction * action) {}];
                                          [alert addAction:OKAction];
                                          [self presentViewController:alert animated:YES completion:nil];
                                          dispatch_semaphore_signal(sem);
                                          return;
                                      }
                                  }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}


-(void)downloadMedicalRecordImageFromAPI{
    // create url
    NSURL *url = [NSURL URLWithString:APIURL];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
//    sessionConfig.timeoutIntervalForRequest = 5.0;
//    sessionConfig.timeoutIntervalForResource = 5.0;
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
    //create JSON data to post to API

    NSDictionary *account = @{
                              @"Partner" :self.partner,
                              @"Mode":@"0",
                              @"MedicalRecord":self.medicalRecordID,
                              };
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:account options:NSJSONWritingPrettyPrinted error:&error];
    [urlRequest setHTTPBody:jsondata];
    dispatch_semaphore_t    sem;
    sem = dispatch_semaphore_create(0);

    NSURLSessionTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

                                          if((long)[httpResponse statusCode] == 200  && error ==nil)
                                          {
                                              NSError *parsJSONError = nil;
                                              self.responseJSONData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              if (self.responseJSONData != nil) {
//                                                  [self saveMedicalRecordToCoreData];
                                              }else{

                                              }
                                              //stop waiting after get response from API
                                              dispatch_semaphore_signal(sem);
                                          }
                                          else{
                                              NSError *parsJSONError = nil;
                                              if (data ==nil) {
                                                  UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Internet Error"
                                                                                                                 message:nil
                                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                                  UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                     style:UIAlertActionStyleDefault
                                                                                                   handler:^(UIAlertAction * action) {}];
                                                  [alert addAction:OKAction];
                                                  [self presentViewController:alert animated:YES completion:nil];
                                                  dispatch_semaphore_signal(sem);

                                                  return;
                                              }
                                              NSDictionary *errorDic = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &parsJSONError];
                                              NSArray *errorArray = [errorDic objectForKey:@"Errors"];
                                              //                                              NSLog(@"\n\n\nError = %@",[errorArray objectAtIndex:0]);

                                              UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                                             message:[errorArray objectAtIndex:0]
                                                                                                      preferredStyle:UIAlertControllerStyleAlert];

                                              UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                 style:UIAlertActionStyleDefault
                                                                                               handler:^(UIAlertAction * action) {}];
                                              [alert addAction:OKAction];
                                              [self presentViewController:alert animated:YES completion:nil];
                                              dispatch_semaphore_signal(sem);
                                              return;
                                          }
                                      }];
    [dataTask resume];
    //start waiting until get response from API
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.medicalRecordImages = [[NSMutableArray alloc]init];

    [self loadPartnerFromCoredata];
    [self downloadMedicalRecordImageFromAPI];
    NSArray *imageArray = [self.responseJSONData objectForKey:@"MedicalImages"];

    for (int index=0; index < imageArray.count; index ++) {
        NSDictionary *imageDic = imageArray[index];
        NSString *base64String = [imageDic objectForKey:@"Image"];



        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];

        //initiate image from data

        UIImage *convertImage = [[UIImage alloc] initWithData:data];

        [self.medicalRecordImages addObject:convertImage];
        [self.collectionView reloadData];
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.topViewController.title=@"MedicalRecord Images";
    //setup barbutton
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addImage:)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = rightBarButton;
}

-(IBAction)addImage:(id)sender{
    UIImagePickerController *myImagePicker = [[UIImagePickerController alloc] init];
    myImagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    myImagePicker.delegate = self;
    [self presentViewController:myImagePicker animated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [picker dismissViewControllerAnimated:YES completion:^{}];
    [self uploadMedicalRecordImageToAPI:image];
}





- (void)viewDidLoad {
    [super viewDidLoad];
    self.medicalRecordImages = [[NSMutableArray alloc]init];
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView setShowsHorizontalScrollIndicator:NO];
    [self.collectionView setShowsVerticalScrollIndicator:NO];
    // Do any additional setup after loading the view.




}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"showMedicalRecordPhoto"]) {
        NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
        MedicalRecordImageShowViewController *destViewController = segue.destinationViewController;
        NSIndexPath *indexPath = [indexPaths objectAtIndex:0];
        destViewController.displayImage = self.selectedImage;//[self.recipeImages[indexPath.section] objectAtIndex:indexPath.row];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
//    UICollectionReusableView *reusableview = nil;
//    if (kind == UICollectionElementKindSectionHeader) {
//        MedicalRecordListCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
//        NSString *title = @"20/7/2017";
//        headerView.dateTimeLabel.text = title;
//        headerView.dateTimeLabel.textColor = [UIColor whiteColor];
//        headerView.backgroundColor = [UIColor colorWithRed:52/255.0 green:152/255.0 blue:219/255.0 alpha:1.0];
//
//        reusableview = headerView;
//    }
//    
//    return reusableview;
//}
#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.medicalRecordImages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    UIImageView * imageView = [[UIImageView alloc]init];
    imageView.image = [self.medicalRecordImages objectAtIndex:indexPath.row];//[UIImage imageNamed:[self.recipeImages[indexPath.section] objectAtIndex:indexPath.row]];
    cell.layer.cornerRadius = 5;

    cell.layer.masksToBounds = YES;
    cell.backgroundView = imageView;

    // Configure the cell
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {
    self.selectedImage = [self.medicalRecordImages objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"showMedicalRecordPhoto" sender:self];
}

-(CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return  CGSizeMake(([UIScreen mainScreen].bounds.size.width-40)/3,([UIScreen mainScreen].bounds.size.width-40)/3) ;
}

-(UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    collectionViewLayout.minimumInteritemSpacing=1;
    collectionViewLayout.minimumLineSpacing = 10;
    return UIEdgeInsetsMake(30, 10, 30, 10);
}
#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
