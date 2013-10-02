//
//  ContactsViewController.m
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import "ContactsViewController.h"
#import "ContactsCell.h"
#import "Contact.h"
#import "CallManager.h"
#import <objc/runtime.h>

static const char associatedContact;

@interface ContactsViewController ()<
UITableViewDataSource,
UITableViewDelegate,
UIAlertViewDelegate>{
    
    IBOutlet UITableView *contactsTableView;
    
}

@property (nonatomic, retain) NSMutableArray *contacts;

@end

@implementation ContactsViewController
@synthesize contacts;

- (void)dealloc {
    [contactsTableView release];
    [contacts release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    contacts = [[NSMutableArray alloc] init];
    
    [contactsTableView registerNib:[UINib nibWithNibName:@"ContactsCell" bundle:nil] forCellReuseIdentifier:kContactsCellReusableIdentifier];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate && UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [contacts count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 66.0f;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:kContactsCellReusableIdentifier];
    Contact *contact = contacts[indexPath.row];
    [cell setContact:contact];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Contact *contact = contacts[indexPath.row];
    contact.activeCall = CallStateWaiting;
    [[CallManager sharedInstance] call:contact];
}

#pragma mark - ContactCallDelegate
- (void)callFromContact:(Contact *)contact{
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Incomming call"
                                                         message:@""
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Accept", nil] autorelease];
    Contact *ctx = [self findContact:contact];
    ctx.ipAddress = contact.ipAddress;
    ctx.activeCall = CallStateWaiting;
    
    objc_setAssociatedObject(alertView, &associatedContact, ctx, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alertView show];
    
    [contactsTableView reloadData];
}

- (void)callAccepted:(Contact *)contact{
    Contact *ctx = [self findContact:contact];
    [ctx setActiveCall:CallStateConnected];
    [contactsTableView reloadData];
}

- (void)callDeclined:(Contact *)contact{
    Contact *ctx = [self findContact:contact];
    [ctx setActiveCall:CallStateNone];
    [contactsTableView reloadData];
}

- (void)contactConnected:(Contact *)contact{
    if (![self contactExists:contact]){
        [self.contacts addObject:contact];
        [contactsTableView reloadData];
    }
}

- (void)contactDisconnected:(Contact *)contact{
    BOOL reload = NO;
    for (int i = self.contacts.count - 1; i > -1; i--){
        if ([[self.contacts[i] service] isEqual:contact.service]){
            [self.contacts removeObjectAtIndex:i];
            reload = YES;
        }
    }
    if (reload){
        [contactsTableView reloadData];
    }
}

- (void)callEnded:(Contact *)contact{
    //TODO: implement
    NSAssert(NO, @"not implemented");
}

- (void)removeAllContacts{
    [self.contacts removeAllObjects];
    [contactsTableView reloadData];
}

#pragma mark - other 

- (BOOL)contactExists:(Contact*)contact{
    return [self findContact:contact] != nil;
}

- (Contact*)findContact:(Contact*)contact{
    __block Contact* con = nil;
    __block BOOL isFound = NO;
    [self.contacts enumerateObjectsUsingBlock:^(Contact *obj, NSUInteger idx, BOOL *stop) {
        *stop = [contact.service isEqual:obj.service] || [contact.displayName rangeOfString:obj.displayName].location == 0; // temporarily fix, matching by names, ugly way
        con = obj;
        isFound = *stop;
    }];
    return isFound ? con : nil;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    Contact *contact = objc_getAssociatedObject(alertView, &associatedContact);
    CallManager *manager = [CallManager sharedInstance];
    switch (buttonIndex) {
        case 0:
            [manager declineCallFrom:contact];
            break;
        default:
        case 1:
            [manager acceptCallFrom:contact];
            break;
    }
}


@end
