//
//  ViewController.h
//  CouchbaseMobileTableView
//
//  Created by Mick Thompson on 9/18/11.
//  Copyright (c) 2011 DavidMichaelThompson.com. All rights reserved.
//

#import "ViewController.h"
//#import "ConfigViewController.h"
#import "AppDelegate.h"

#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/RESTBody.h>
#import <Couchbase/CouchbaseMobile.h>


@interface ViewController ()
@property(nonatomic, retain)CouchDatabase *database;
@property(nonatomic, retain)NSURL* remoteSyncURL;
- (void)showSyncStatus;
- (void)hideSyncStatus;
- (void)updateSyncURL;
- (void)forgetSync;
@end


@implementation ViewController


@synthesize dataSource;
@synthesize database;
@synthesize tableView;
@synthesize remoteSyncURL;


#pragma mark - View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CouchUITableSource class];     // Prevents class from being dead-stripped by linker
    
    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundColor:[UIColor clearColor]];   
}


- (void)dealloc {
    [self forgetSync];
    [database release];
    [super dealloc];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
}


- (void)useDatabase:(CouchDatabase*)theDatabase {
    self.database = theDatabase;
      
    CouchLiveQuery* query = [[database getAllDocuments] asLiveQuery];
    query.descending = YES;
    
	[self.dataSource setQuery:query];
	self.dataSource.labelProperty = @"text";	
    [self updateSyncURL];
}


- (void)showErrorAlert: (NSString*)message forOperation: (RESTOperation*)op {
    NSLog(@"%@: op=%@, error=%@", message, op, op.error);
    // Can add an alert view here if desired.
    
}


#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // delegate method when cell are selected.

}


#pragma mark - Editing:


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    // Get the name of the item from the text field:
	NSString *text = addItemTextField.text;
    if (text.length == 0) {
        return;
    }
    [addItemTextField setText:nil];
    
    // Get the current date+time as a string in standard JSON format:
    NSString* dateString = [RESTBody JSONObjectWithDate: [NSDate date]];
    
    // Construct a unique document ID that will sort chronologically:
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *guid = (NSString*)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
	NSString *docId = [NSString stringWithFormat:@"%@-%@", dateString, guid];
    [guid release];
    
    // Create the new document's properties:
	NSDictionary *inDocument = [NSDictionary dictionaryWithObjectsAndKeys:text, @"text",
                                dateString, @"created_at",
                                nil];
    
    // Save the document, asynchronously:
    CouchDocument* doc = [database documentWithID: docId];
    RESTOperation* op = [doc putProperties:inDocument];
    [op onCompletion: ^{
        if (op.error)
            [self showErrorAlert: @"Couldn't save the new item" forOperation: op];
        // Re-run the query:
		[self.dataSource.query start];
	}];
    [op start];
}



- (void)couchTableSource:(CouchUITableSource*)source
         operationFailed:(RESTOperation*)op
{
    NSString* message = op.isDELETE ? @"Couldn't delete item" : @"Operation failed";
    [self showErrorAlert: message forOperation: op];
}
#pragma mark - SYNC:

- (void) forgetSync {
    [_pull removeObserver: self forKeyPath: @"completed"];
    [_pull release];
    _pull = nil;
    [_push removeObserver: self forKeyPath: @"completed"];
    [_push release];
    _push = nil;
}

- (void)updateSyncURL {
    if (!self.database)
        return;
    remoteSyncURL = [NSURL URLWithString: @"http://dmt.iriscouch.com/couchbasedemo"];
    
    [self forgetSync];
    NSLog(@" replications: %d", [[self.database replications] count]);
    NSArray* repls = [self.database replicateWithURL: remoteSyncURL exclusively: YES];
    _pull = [[repls objectAtIndex: 0] retain];
    _push = [[repls objectAtIndex: 1] retain];
    [_pull addObserver: self forKeyPath: @"completed" options: 0 context: NULL];
    [_push addObserver: self forKeyPath: @"completed" options: 0 context: NULL];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == _pull || object == _push) {
        unsigned completed = _pull.completed + _push.completed;
        unsigned total = _pull.total + _push.total;
        NSLog(@"SYNC progress: %u / %u", completed, total);
        if (total > 0 && completed < total) {
            [self showSyncStatus];
            [progress setProgress:(completed / (float)total)];
            database.server.activityPollInterval = 0.5;   // poll often while progress is showing
        } else {
            [self hideSyncStatus];
            database.server.activityPollInterval = 2.0;   // poll less often at other times
        }
    }
}

- (void)hideSyncStatus {
    self.navigationItem.rightBarButtonItem = nil;
}


- (void)showSyncStatus {
    if (!progress) {
        progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        CGRect frame = progress.frame;
        frame.size.width = self.view.frame.size.width / 4.0;
        progress.frame = frame;
    }
    UIBarButtonItem* progressItem = [[UIBarButtonItem alloc] initWithCustomView:progress];
    progressItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = [progressItem autorelease];
}

@end
