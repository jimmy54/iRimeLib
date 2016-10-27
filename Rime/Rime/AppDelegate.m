//
//  AppDelegate.m
//  Rime
//
//  Created by jimmy54 on 5/30/16.
//  Copyright © 2016 jimmy54. All rights reserved.
//

#import "AppDelegate.h"

#import "RimeWrapper.h"
#import "rime_api.h"
#import "NSString+Path.h"

@interface AppDelegate ()<RimeNotificationDelegate>{
RimeSessionId rimeSessionId_;
}



@end

@implementation AppDelegate{
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Set Rime notification handler
    [RimeWrapper setNotificationDelegate:self];
    
    // Start Rime service
    if ([RimeWrapper startService]) {
        NSLog(@"Rime service started.");
    } else {
        NSLog(@"Failed to start Rime service.");
    }
    
//
    [self handleEvent];
    
    
    
    
//    
//    NSFileManager *fm = [NSFileManager defaultManager];
//    NSString *sPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/XIME"];
//    NSString *dPath = [NSString rimeResource];
//    
//    NSError *err = nil;
//    
//    BOOL res = [fm copyItemAtPath:sPath toPath:dPath error:&err];
//    if (res == NO) {
//        NSLog(@"fail to copy");
//    }
//    
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // Stop Rime service
//    [RimeWrapper stopService];
    
    // Destroy IMKServer
}



#pragma mark Key Up Event Handler

- (BOOL)handleEvent{
    BOOL handled = NO;
    
    // Rime session may failed to create during deployment, so here is a second check to make sure there is an available sessios.
    if (![RimeWrapper isSessionAlive:rimeSessionId_]) {
        rimeSessionId_ = [RimeWrapper createSession];
        if (!rimeSessionId_) { // If still failed to create Rime session, do not handle this event.
            return NO;
        }
    }
    
    

            char keyChar = '0';
            
            int rimeKeyCode = [RimeWrapper rimeKeyCodeForOSXKeyCode:0];
            if (!rimeKeyCode) { // If this is not a special keyCode we could recognize, then get keyCode from keyChar.
                rimeKeyCode = [RimeWrapper rimeKeyCodeForKeyChar:keyChar];
            }
//            int rimeModifier = [RimeWrapper rimeModifierForOSXModifier:modifierFlags];
            handled = [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:104 rimeModifier:0];
            
            [self syncWithRime];
    
    
    return handled;
}


#pragma mark Sync With Rime Service

/**
 * We have to sync data and action between XIME and Rime with the following strategy:
 *
 * Data:
 *  XIME Composed Text <-- Rime Context Preedited Text
 *  XIME Candidate Window <-- Rime Context
 *
 * Action:
 *  XIME Commit Composition --> Rime Commit Composition
 *  XIME Insert Text <-- Rime Commit Composition
 *  XIME Cancel Composition --> Rime Clear Composition
 */
- (void)syncWithRime {
    
    if (!rimeSessionId_) { // Cannot sync if there is no rime session
        return;
    }
    
//    // Action: XIME Commit Composition --> Rime Commit Composition
//    if (committed_) { // Flagged in commitComposition:(id)sender
//        committed_ = NO;
//        [RimeWrapper commitCompositionForSession:rimeSessionId_];
//    }
//    
//    // Action: XIME Insert Text <-- Rime Commit Composition
//    NSString *rimeComposedText = [RimeWrapper consumeComposedTextForSession:rimeSessionId_];
//    if (rimeComposedText) { // If there is composed text to consume, we can infer that Rime did commit action
//    }
//    
//    // Action: XIME Cancel Composition --> Rime Clear Composition
//    if (canceled_) {
//        canceled_ = NO;
//        [RimeWrapper clearCompositionForSession:rimeSessionId_];
//    }
//    
//    XRimeContext *context = [RimeWrapper contextForSession:rimeSessionId_];
//    
    bool res = false;

    
//    RIME_API Bool RimeGetOption(RimeSessionId session_id, const char* option);
    
    const char *op = "test";
    RimeGetOption(rimeSessionId_, op);
    
    
    //schme list
    RimeSchemaList list;
    res = RimeGetSchemaList(&list);
    
    RimeFreeSchemaList(&list);
    
    
    
    //RimeApi *api = rime_get_api();
    res = rime_get_api()->select_candidate(rimeSessionId_, 0);
    
    
    
    
    //candidate
    RimeCandidateListIterator ite;
    res = RimeCandidateListBegin(rimeSessionId_, &ite);
    if (res == false) {
        return;
    }
    
    while (RimeCandidateListNext(&ite)) {
        
        NSString *s = [NSString stringWithUTF8String:ite.candidate.text];
        NSLog(@"%@", s);
    }
    
    RimeCandidateListEnd(&ite);
    

}

@end
