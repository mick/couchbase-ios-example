//
//  AppDelegate.m
//  CouchbaseMobileTableView
//
//  Created by Mick Thompson on 9/18/11.
//  Copyright (c) 2011 DavidMichaelThompson.com. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

@implementation AppDelegate

@synthesize window;
@synthesize navController;
@synthesize database;

- (void)dealloc
{
    [window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [window addSubview:navController.view];
    [window makeKeyAndVisible];
    
    CouchbaseMobile* cb = [[CouchbaseMobile alloc] init];
    cb.delegate = self;
    NSAssert([cb start], @"Couchbase didn't start! Error = %@", cb.error);
        
    return YES;
}


-(void)connectToServer:(NSURL*)serverURL {
    NSLog(@"couchbaseMobile:didStart: <%@>", serverURL);
    gCouchLogLevel = 2;
    
    ViewController* root = (ViewController*)navController.topViewController;
    
    if (!database) {
        // This is the first time the server has started:
        CouchServer *server = [[CouchServer alloc] initWithURL: serverURL];
        self.database = [server databaseNamed: @"couchbase-demo"];
        [server release];
        
    }
    RESTOperation* op = [database create];
    if (![op wait] && op.httpStatus != 412) {
        // failed to contact the server or create the database
        // (a 412 status is OK; it just indicates the db already exists.)
        NSAssert(NO, @"CouchCocoa failed to connect.");
    }
      
    [root useDatabase: database]; 
   
}

-(void)couchbaseMobile:(CouchbaseMobile*)couchbase didStart:(NSURL*)serverURL {
    NSLog(@"Couchbase is Ready, go! %@", serverURL);
   
    [self connectToServer:serverURL];
    return;
}



-(void)couchbaseMobile:(CouchbaseMobile*)couchbase failedToStart:(NSError*)error {
    NSAssert(NO, @"Couchbase failed to initialize: %@", error);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
