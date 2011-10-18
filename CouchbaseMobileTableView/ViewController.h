//
//  ViewController.h
//  CouchbaseMobileTableView
//
//  Created by Mick Thompson on 9/18/11.
//  Copyright (c) 2011 DavidMichaelThompson.com. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CouchCocoa/CouchUITableSource.h>
@class CouchDatabase;


@interface ViewController : UIViewController <CouchUITableDelegate, UITextFieldDelegate>

@property(nonatomic, retain) IBOutlet UITableView *tableView;
@property(nonatomic, retain) IBOutlet CouchUITableSource *dataSource;
@property(nonatomic, retain) IBOutlet UITextField *addItemTextField;

-(void)useDatabase:(CouchDatabase*)theDatabase;

@end
