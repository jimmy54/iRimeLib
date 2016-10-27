//
//  SelectInputViewController.m
//  iRime
//
//  Created by jimmy54 on 8/15/16.
//  Copyright © 2016 jimmy54. All rights reserved.
//

#import "SelectInputViewController.h"
//#import "IASKSpecifier.h"


//#import "IASKSettingsReader.h"
//#import "IASKSettingsStoreUserDefaults.h"

#import "RimeWrapper.h"
#import <rime_api.h>
//#import "NSString+Path.h"

@interface SelectInputViewController ()<UITableViewDelegate, UITableViewDataSource>{
    RimeSessionId sessionId;
}


@property(nonatomic, strong)NSMutableArray *schemaTitles;
@property(nonatomic, strong)NSMutableArray *schemaValues;
@property(nonatomic, strong)NSString *currentSchema;





@end

@implementation SelectInputViewController


//- (id)initWithFile:(NSString*)file specifier:(IASKSpecifier*)specifier {
//    if ((self = [super init])) {
//        // custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    sessionId = [RimeWrapper createSession];
    
    [self setupSchemaList];
    [self getCurrentSchema];
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [RimeWrapper redeployWithFastMode:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)setupSchemaList
{
    RimeSchemaList schemaList;
    
    Bool r = rime_get_api()->get_schema_list(&schemaList);
    if (r == NO) {
        NSLog(@"get schema list fail");
        return;
    }
    
    RimeSchemaListItem *item = nil;
    self.schemaTitles = [NSMutableArray new];
    self.schemaValues = [NSMutableArray new];
    
    for (int i = 0; i < schemaList.size; i++) {
        
        item = &schemaList.list[i];
        [self.schemaTitles addObject:[NSString stringWithUTF8String:item->name]];
        [self.schemaValues addObject:[NSString stringWithUTF8String:item->schema_id]];
        
    }
    

    
    rime_get_api()->free_schema_list(&schemaList);
    
}

-(void)getCurrentSchema
{
     if ([RimeWrapper isSessionAlive:sessionId] == NO) {
        _currentSchema = nil;
        return;
    }
    
    char schemaId[64];
    size_t s = 64;
    BOOL r = rime_get_api()->get_current_schema(sessionId, schemaId, s);
    if (r == NO) {
        NSLog(@"get current schema fail");
    }
    
    _currentSchema = [NSString stringWithUTF8String:schemaId];
}

-(void)setCurrentSchema:(NSString *)currentSchema
{
    if ([RimeWrapper isSessionAlive:sessionId] == NO) {
        _currentSchema = nil;
        return;
    }
    BOOL res = rime_get_api()->select_schema(sessionId, [currentSchema UTF8String]);
    if (res == NO) {
        NSLog(@"set the schema fail");
        _currentSchema = nil;
        return;
    }
    _currentSchema = currentSchema;
    
    res = RimeSetActiveSchema([currentSchema UTF8String]);
    
    
    
    
//    NSString *s = [NSString stringWithFormat:@"%@/%@.schema.yaml",[NSString rimeResource], currentSchema];
//    const char *f = [s UTF8String];
//    res = rime_get_api()->deploy_schema(f);
    
//    [RimeWrapper redeployWithFastMode:YES];
    
}



#pragma mark -- table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.schemaTitles.count;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"schemaCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"schemaCell"];
    }
    
    cell.textLabel.text = [self.schemaTitles objectAtIndex:[indexPath row]];
    
    NSString *schema = [self.schemaValues objectAtIndex:[indexPath row]];
    if ([schema isEqualToString:self.currentSchema]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
 
    NSString *schema = [self.schemaValues objectAtIndex:[indexPath row]];
    
    self.currentSchema = schema;

    
    [tableView reloadData];
    
}


@end
