//
//  AppDelegate.h
//  CouchbaseMobileTableView
//
//  Created by Mick Thompson on 9/18/11.
//  Copyright (c) 2011 DavidMichaelThompson.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Couchbase/CouchbaseMobile.h>
#import <CouchCocoa/CouchCocoa.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, CouchbaseDelegate>
{
    CouchDatabase *database;
    UINavigationController *navController;
    UIWindow *window; 
}

@property(nonatomic, retain)CouchDatabase *database;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;

@end
