//
//  ViewController.m
//  02-BLE(import)
//
//  Created by xiaomage on 15/10/8.
//  Copyright © 2015年 小码哥. All rights reserved.
//

#import "ViewController.h"
#import "XMGCenterBLEVC.h"
#import "XMGPeripheralBLEVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)centerBLE:(id)sender {
    [self.navigationController pushViewController:[[XMGCenterBLEVC alloc] init] animated:YES];
}
- (IBAction)peripheralBLE:(id)sender {
    [self.navigationController pushViewController:[[XMGPeripheralBLEVC alloc] init] animated:YES];
}

@end
