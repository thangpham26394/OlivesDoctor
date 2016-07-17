//
//  MedicalRecordImageShowViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 7/17/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "MedicalRecordImageShowViewController.h"

@interface MedicalRecordImageShowViewController ()
@property(strong,nonatomic) UIScrollView *scrollView;
@property(strong,nonatomic) UIImageView *imageView;
@end

@implementation MedicalRecordImageShowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.translucent = NO;
    UIImage *initialImage = [UIImage imageNamed:self.imageName];
    self.imageView = [[UIImageView alloc] init];
    self.imageView.image = initialImage;
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView .autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.scrollView.backgroundColor = [UIColor blackColor];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    self.scrollView.maximumZoomScale = 2.0;
    self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height);
    self.scrollView.contentSize = self.imageView.bounds.size;
    self.scrollView.contentOffset = CGPointMake(self.imageView.frame.size.width/2, self.imageView.frame.size.height/2);
    [self.scrollView addSubview:self.imageView];
    [self.view addSubview:self.scrollView];

    self.scrollView.delegate = self;
    [self setupGestureRecognizer];
    [self setZoomScale];
}
-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self setZoomScale];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGSize imageViewSize = self.imageView.frame.size;
    CGSize scrollViewSize = self.scrollView.bounds.size;
    CGFloat verticalPadding =0 ;
    if (imageViewSize.height < scrollViewSize.height) {
        verticalPadding = (scrollViewSize.height - imageViewSize.height) / 2 ;
    }

    CGFloat horizontalPadding = 0;
    if (imageViewSize.width < scrollViewSize.width) {
        horizontalPadding = (scrollViewSize.width - imageViewSize.width)/ 2;
    }

    self.scrollView.contentInset =  UIEdgeInsetsMake(verticalPadding, horizontalPadding,verticalPadding, horizontalPadding);
    
}

-(void) setZoomScale{
    CGSize imageViewSize = self.imageView.bounds.size;
    CGSize scrollViewSize = self.scrollView.bounds.size;
    CGFloat widthScale = scrollViewSize.width / imageViewSize.width;
    CGFloat heightScale = scrollViewSize.height / imageViewSize.height;

    self.scrollView.minimumZoomScale = MIN(widthScale, heightScale);
    self.scrollView.zoomScale = 1.0;
}

-(void) setupGestureRecognizer {
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];

    //    [doubleTap setDelegate:self];
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];
}

- (void)handleDoubleTap:(UIPanGestureRecognizer *)recognizer{
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];

    } else {
        [self.scrollView setZoomScale:self.scrollView.maximumZoomScale animated:YES];
        
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
