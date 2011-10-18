//
//  AppDelegate.m
//  CouchbaseMobileTableView
//
//  Created by Mick Thompson on 9/18/11.
//  Copyright (c) 2011 DavidMichaelThompson.com. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <CouchCocoa/CouchCocoa.h>


@implementation AppDelegate

@synthesize window = window_;
@synthesize navController = navController_;
@synthesize database = database_;


- (void)dealloc
{
    [window_ release];
    [super dealloc];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [window_ addSubview:navController_.view];
    [window_ makeKeyAndVisible];
    
    CouchbaseMobile* cb = [[CouchbaseMobile alloc] init];
    cb.delegate = self;
    NSAssert([cb start], @"Couchbase didn't start! Error = %@", cb.error);
        
    return YES;
}


-(void)couchbaseMobile:(CouchbaseMobile*)couchbase didStart:(NSURL*)serverURL {
    gCouchLogLevel = 1;
    gRESTLogLevel = kRESTLogRequestURLs;
    
    if (!database_) {
        // This is the first time the server has started:
        CouchServer *server = [[CouchServer alloc] initWithURL: serverURL];
        // Track active operations so we can wait for their completion in didEnterBackground, below
        server.tracksActiveOperations = YES;
        self.database = [server databaseNamed: @"couchbase-demo"];
        [server release];
        
        RESTOperation* op = [database_ create];
        if (![op wait] && op.httpStatus != 412) {
            // failed to contact the server or create the database
            // (a 412 status is OK; it just indicates the db already exists.)
            NSAssert(NO, @"CouchCocoa failed to connect.");
        }
        
        ViewController* root = (ViewController*)navController_.topViewController;
        [root useDatabase: database_]; 
    }
    
    database_.tracksChanges = YES;
}


-(void)couchbaseMobile:(CouchbaseMobile*)couchbase failedToStart:(NSError*)error {
    NSAssert(NO, @"Couchbase failed to initialize: %@", error);
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"------ applicationDidEnterBackground");
    // Turn off the _changes watcher:
    database_.tracksChanges = NO;
    
	// Make sure all transactions complete, because going into the background will
    // close down the CouchDB server:
    [RESTOperation wait: database_.server.activeOperations];
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"------ applicationWillEnterForeground");
    // Don't reconnect to the server yet ... wait for it to tell us it's back up,
    // by calling couchbaseMobile:didStart: again.
}

@end
