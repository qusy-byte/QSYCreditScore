//
//  ViewController.m
//  QSYCreditScore
//
//  Created by SL on 2016/12/8.
//  Copyright © 2016年 QSY. All rights reserved.
//

#import "ViewController.h"
#import "QSYCreditScoreView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet QSYCreditScoreView *creditScoreView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSInteger creditNumber = arc4random_uniform(600) + 350;
    
    NSLog(@"creditNumber = %zd",creditNumber);
    
    self.creditScoreView.creditScoreNumber = creditNumber;
    [self.creditScoreView updateCreditScore];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
