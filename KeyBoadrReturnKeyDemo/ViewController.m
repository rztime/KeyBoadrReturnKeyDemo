//
//  ViewController.m
//  KeyBoadrReturnKeyDemo
//
//  Created by ruozui on 2019/12/24.
//  Copyright © 2019 rztime. All rights reserved.
//

#import "ViewController.h"
#import "RZKeyboardReturnKeyUtil.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [RZKeyboardReturnKeyUtil shareInstance].enable = YES;
    
    for (NSInteger i = 0; i < 10; i++) {
        UITextField *textfield = [[UITextField alloc] init];
        [self.view addSubview:textfield];
        textfield.frame = CGRectMake(10, 100 + i * 50, 200, 44);
        textfield.backgroundColor = UIColor.grayColor;
    }
}


@end
