//
//  PatientDetailsViewController.m
//  Olives
//
//  Created by Tony Tony Chopper on 6/25/16.
//  Copyright © 2016 Thang. All rights reserved.
//

#import "PatientDetailsViewController.h"

@interface PatientDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;


@end

@implementation PatientDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width / 2;
    self.avatarImage.clipsToBounds = YES;
    self.sendMessageButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:153/255.0 blue:153/255.0 alpha:1.0];

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

    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"medicalInfoCell" forIndexPath:indexPath];

    // Configure the cell...

    return cell;
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
