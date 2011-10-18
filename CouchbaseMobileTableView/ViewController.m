//
//  ViewController.h
//  CouchbaseMobileTableView
//
//  Created by Mick Thompson on 9/18/11.
//  Copyright (c) 2011 DavidMichaelThompson.com. All rights reserved.
//

#import "ViewController.h"
#import <CouchCocoa/CouchCocoa.h>
#import <Couchbase/CouchbaseMobile.h>


// Remote database to sync with:
#define kRemoteSyncURLStr @"http://dmt.iriscouch.com/couchbasedemo"


@interface ViewController ()
@property(nonatomic, retain)CouchDatabase *database;
- (void)startSync;
- (void)showSyncStatus;
- (void)hideSyncStatus;
@end


@implementation ViewController
{
    CouchPersistentReplication* pull_;
    CouchPersistentReplication* push_;
    UIProgressView *progress_;
}


@synthesize dataSource = dataSource_;
@synthesize database = database_;
@synthesize tableView = tableView_;
@synthesize addItemTextField = addItemTextField_;


#pragma mark - View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CouchUITableSource class];     // Prevents class from being dead-stripped by linker
}


- (void)dealloc {
    [pull_ release];
    [push_ release];
    [database_ release];
    [tableView_ release];
    [dataSource_ release];
    [addItemTextField_ release];
    [super dealloc];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
}


- (void)useDatabase:(CouchDatabase*)theDatabase {
    self.database = theDatabase;
    
    // Create a view function that will return docs by descending 'created_at':
    CouchDesignDocument* design = [theDatabase designDocumentWithName: @"grocery"];
    [design defineViewNamed: @"byDate"
                        map: @"function(doc) {if (doc.created_at) emit(doc.created_at, doc);}"];
    CouchLiveQuery* query = [[design queryViewNamed: @"byDate"] asLiveQuery];
    query.descending = YES;
    
    // Start the query the table view will run:
	self.dataSource.query = query;
	self.dataSource.labelProperty = @"text";
    
    [self startSync];
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
    // delegate method when row is selected.
}


#pragma mark - Editing:


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    
	return YES;
}


-(void)textFieldDidEndEditing:(UITextField *)textField {
    // Get the name of the item from the text field:
	NSString *text = addItemTextField_.text;
    if (text.length == 0) {
        return;
    }
    [addItemTextField_ setText:nil];
    
    // Create the new document's properties:
	NSDictionary *inDocument = [NSDictionary dictionaryWithObjectsAndKeys:text, @"text",
                                [RESTBody JSONObjectWithDate: [NSDate date]], @"created_at",
                                nil];
    
    // Save the document, asynchronously:
    CouchDocument* doc = [database_ untitledDocument];
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


#pragma mark - Sync:


- (void)startSync {
    NSURL* remoteSyncURL = [NSURL URLWithString: kRemoteSyncURLStr];
    NSArray* repls = [self.database replicateWithURL: remoteSyncURL exclusively: YES];
    pull_ = [[repls objectAtIndex: 0] retain];
    push_ = [[repls objectAtIndex: 1] retain];
    [pull_ addObserver: self forKeyPath: @"completed" options: 0 context: NULL];
    [push_ addObserver: self forKeyPath: @"completed" options: 0 context: NULL];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == pull_ || object == push_) {
        unsigned completed = pull_.completed + push_.completed;
        unsigned total = pull_.total + push_.total;
        NSLog(@"SYNC progress: %u / %u", completed, total);
        if (total > 0 && completed < total) {
            [self showSyncStatus];
            [progress_ setProgress:(completed / (float)total)];
            database_.server.activityPollInterval = 0.5;   // poll often while progress is showing
        } else {
            [self hideSyncStatus];
            database_.server.activityPollInterval = 2.0;   // poll less often at other times
        }
    }
}


- (void)hideSyncStatus {
    if (progress_) {
        self.navigationItem.rightBarButtonItem = nil;
        [progress_ release];
        progress_ = nil;
    }
}


- (void)showSyncStatus {
    if (!progress_) {
        progress_ = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        CGRect frame = progress_.frame;
        frame.size.width = self.view.frame.size.width / 4.0;
        progress_.frame = frame;

        UIBarButtonItem* progressItem = [[UIBarButtonItem alloc] initWithCustomView:progress_];
        progressItem.enabled = NO;
        self.navigationItem.rightBarButtonItem = [progressItem autorelease];
    }
}

@end
