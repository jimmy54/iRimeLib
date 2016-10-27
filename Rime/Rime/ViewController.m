//
//  ViewController.m
//  Rime
//
//  Created by jimmy54 on 5/30/16.
//  Copyright © 2016 jimmy54. All rights reserved.
//

#import "ViewController.h"
#import <rime_api.h>
#import "SelectInputViewController.h"
#import "NSString+Path.h"

//#include <boost/algorithm/string.hpp>

//rime_deployer.cc




@interface ViewController (){
    
}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    
}

void notification_handler(void* context_object, RimeSessionId session_id,
                          const char* message_type, const char* message_value) {
    if (!strcmp(message_type, "deploy")) {
        if (!strcmp(message_value, "start")) {
        }
        else if (!strcmp(message_value, "success")) {
        }
        else if (!strcmp(message_value, "failure")) {
        }
        return;
    }

}


-(IBAction)tapBtn:(id)sender
{
    
    SelectInputViewController *vc = [SelectInputViewController new];
    [self.navigationController pushViewController:vc animated:YES];
    
    
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
