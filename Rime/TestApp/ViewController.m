//
//  ViewController.m
//  TestApp
//
//  Created by jimmy54 on 8/14/16.
//  Copyright © 2016 jimmy54. All rights reserved.
//

#import "ViewController.h"
#import "rime_api.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    RimeSchemaList list;
    rime_get_api()->get_schema_list(&list);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
