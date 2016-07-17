//
//  MedicalRecordImagesCollectionViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/17/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MedicalRecordImagesCollectionViewController.h"
#import "MedicalRecordImageShowViewController.h"
#import "MedicalRecordListCollectionReusableView.h"

@interface MedicalRecordImagesCollectionViewController ()
@property(strong,nonatomic) NSArray *medicalRecordImages;
@end

@implementation MedicalRecordImagesCollectionViewController

static NSString * const reuseIdentifier = @"medicalRecordImage";

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *image = [NSArray arrayWithObjects:@"scrollphoto.png", nil];
    self.medicalRecordImages = image;
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
        destViewController.imageName = @"scrollphoto.png";//[self.recipeImages[indexPath.section] objectAtIndex:indexPath.row];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *reusableview = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        MedicalRecordListCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        NSString *title = @"20/7/2017";
        headerView.dateTimeLabel.text = title;
        headerView.dateTimeLabel.textColor = [UIColor whiteColor];
        headerView.backgroundColor = [UIColor colorWithRed:52/255.0 green:152/255.0 blue:219/255.0 alpha:1.0];

        reusableview = headerView;
    }
    
    return reusableview;
}
#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 3;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    UIImageView * imageView = [[UIImageView alloc]init];
    imageView.image = [UIImage imageNamed:@"scrollphoto.png"]; //[UIImage imageNamed:[self.recipeImages[indexPath.section] objectAtIndex:indexPath.row]];
    cell.layer.cornerRadius = 10;

    cell.layer.masksToBounds = YES;
    cell.backgroundView = imageView;

    // Configure the cell
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath  {
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
