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


@end
