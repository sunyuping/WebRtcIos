//
//  CallManager.m
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import "ContactCallDelegate.h"
#import "CallManager.h"
#import "QServer.h"
#import "Contact.h"
#import <netinet/in.h>
#import <ifaddrs.h>
#import <sys/socket.h>
#import "Call.h"
#import <arpa/inet.h>

static NSString *const kWebRtcMarekBonjourType = @"_witap2._tcp.";

static NSString *const kWebRtcCall  = @"call";
static NSString *const kWebRtcAccept = @"accept";
static NSString *const kWebRtcDecline = @"decline";


NSString* getIPAddress();

__attribute__((constructor))
static void getIPOnStart(){
    @autoreleasepool {
        __unused NSString *ip = getIPAddress();
    }
}

NSString* getIPAddress(){
    static NSString *address = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct ifaddrs *interfaces = NULL;
        struct ifaddrs *temp_addr = NULL;
        int success = 0;
        
        // retrieve the current interfaces - returns 0 on success
        success = getifaddrs(&interfaces);
        if (success == 0)
        {
            // Loop through linked list of interfaces
            temp_addr = interfaces;
            while(temp_addr != NULL)
            {
                if(temp_addr->ifa_addr->sa_family == AF_INET)
                {
                    // Check if interface is en0 which is the wifi connection on the iPhone
                    if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                    {
                        [address release];
                        address = nil;
                        // Get NSString from C String
                        address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                        [address retain];
                    }
                }
                temp_addr = temp_addr->ifa_next;
            }
        }
        
        // Free memory
        freeifaddrs(interfaces);
    });
    
    return address;
}





@interface CallManager ()<
QServerDelegate,
NSStreamDelegate,
NSNetServiceBrowserDelegate,
NSNetServiceDelegate>

@property (nonatomic, retain) QServer                       *server;
@property (nonatomic, retain, readwrite) NSInputStream      *inputStream;
@property (nonatomic, retain, readwrite) NSOutputStream     *outputStream;
@property (nonatomic, assign, readwrite) NSUInteger         streamOpenCount;
@property (nonatomic, retain) NSNetService                  *registeredService;
@property (nonatomic, retain) NSNetServiceBrowser           *browser;
@property (nonatomic, retain) Contact                       *calledContact;

@end

@implementation CallManager
@synthesize server, delegate;
@synthesize inputStream, outputStream;
@synthesize streamOpenCount;
@synthesize browser, registeredService;

- (void)dealloc{
    self.server = nil;
    self.inputStream = nil;
    self.outputStream = nil;
    self.registeredService = nil;
    self.browser = nil;
    self.calledContact = nil;
    [super dealloc];
}

+ (CallManager*)sharedInstance{
    static CallManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CallManager alloc] init];
    });
    return manager;
}

- (void)start{
    NSAssert(delegate, @"CallManager expects delegate here!");
    
    self.server = [[QServer alloc] initWithDomain:@"local." type:kWebRtcMarekBonjourType name:nil preferredPort:0];
    [self.server setDelegate:self];
    [self.server start];
}

- (void)call:(Contact *)contact{            // very very ugly way to make calls
    if (self.calledContact){
        [self send:kWebRtcCall];        // c like call
        return;
    }
    
    BOOL                success;
    NSInputStream *     inStream;
    NSOutputStream *    outStream;
    success = [contact.service getInputStream:&inStream outputStream:&outStream];
    if (success){
        [self closeStreams];
        self.calledContact = contact;
        self.inputStream  = inStream;
        self.outputStream = outStream;
        [self openStreams];
        double delayInSeconds = 2.5;            // again very ugly way to make calls, we have to w8, to setup connection between devices
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self send:kWebRtcCall];        // c like call
        });
    }
}

- (void)acceptCallFrom:(Contact *)contact{
    [Call startTestCallToIp:contact.ipAddress];
    //[self startTestCallToIp:contact.ipAddress];
    [self send:kWebRtcAccept];        // a like accept
}

- (void)declineCallFrom:(Contact *)contact{
    [self send:kWebRtcDecline];        // d like decline
}

- (void)send:(NSString*)message
{
    assert(self.streamOpenCount == 2);
    
    // Only write to the stream if it has space available, otherwise we might block.
    // In a real app you have to handle this case properly but in this sample code it's
    // OK to ignore it; if the stream stops transferring data the user is going to have
    // to tap a lot before we fill up our stream buffer (-:
    
    if ( [self.outputStream hasSpaceAvailable] ) {
        NSInteger   bytesWritten;
        NSString *ip = getIPAddress();
        NSString *outMessage = [NSString stringWithFormat:@"%@:::%@:::%@", message, ip, [registeredService name]];
        const char *outc = [outMessage UTF8String];
        NSData *data = [[[NSData alloc] initWithBytes:outc length:strlen(outc)] autorelease];
        bytesWritten = [self.outputStream write:[data bytes] maxLength:strlen([data bytes])];
    }
}

- (void)setupForNewConnection{
    [self closeStreams];
    
    if (self.server.isDeregistered) {
        [self.server reregister];
    }
}


- (void)openStreams
{
    assert(self.inputStream != nil);            // streams must exist but aren't open
    assert(self.outputStream != nil);
    assert(self.streamOpenCount == 0);
    
    [self.inputStream  setDelegate:self];
    [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream  open];
    
    [self.outputStream setDelegate:self];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    
    self.streamOpenCount = 2;
}

- (void)closeStreams {
    assert( (self.inputStream != nil) == (self.outputStream != nil) );      // should either have both or neither
    if (self.inputStream != nil) {
        [self.server closeOneConnection:self];
        
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream = nil;
        
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
    }
    self.streamOpenCount = 0;
}

- (void)startService{
    registeredService = [[NSNetService alloc] initWithDomain:@"local." type:kWebRtcMarekBonjourType name:self.server.registeredName];
    
    self.browser = [[NSNetServiceBrowser alloc] init];
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:kWebRtcMarekBonjourType inDomain:@"local"];
}

- (void)stopService{
    [self.browser stop];
    self.browser = nil;
    
    [delegate removeAllContacts];
}

#pragma mark - QServer delegate

- (void)serverDidStart:(QServer *)server{
    [self startService];
}

- (id)server:(QServer *)server connectionForInputStream:(NSInputStream *)iStream outputStream:(NSOutputStream *)oStream{
    id  result;
    
    assert( (self.inputStream != nil) == (self.outputStream != nil) );      // should either have both or neither
    
    if (self.inputStream != nil) {
        
        result = nil;
    } else {
        // Start up the new game.  Start by deregistering the server, to discourage
        // Latch the input and output sterams and kick off an open.
        
        self.inputStream  = iStream;
        self.outputStream = oStream;
        
        [self openStreams];
        
        // This is kinda bogus.  Because we only support a single input stream
        // we use the app delegate as the connection object.  It makes sense if
        // you think about it long enough, but it's definitely strange.
        
        result = self;
    }
    
    return result;
}

- (void)server:(QServer *)server didStopWithError:(NSError *)error
// This is called when the server stops of its own accord.  The only reason
// that might happen is if the Bonjour registration fails when we reregister
// the server, and that's hard to trigger because we use auto-rename.  I've
// left an assert here so that, if this does happen, we can figure out why it
// happens and then decide how best to handle it.
{
    //TODO: implement
}

- (void)server:(QServer *)server closeConnection:(id)connection{
// This is called when the server shuts down, which currently never happens.
    //TODO: implement
}

#pragma mark - Connection management

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode{

    switch(eventCode) {            
        case NSStreamEventOpenCompleted:
            break;
            
        case NSStreamEventHasSpaceAvailable: {
            assert(stream == self.outputStream);
            // do nothing
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            char     b[100];
            NSInteger   bytesRead;
            
            assert(stream == self.inputStream);
            
            const char     *c = b;
            bytesRead = [self.inputStream read:c maxLength:100];
            if (bytesRead <= 0) {
                
            } else {

                NSString *str = [[[NSString alloc] initWithBytes:c length:strlen(c) encoding:NSUTF8StringEncoding] autorelease];
                NSArray *componenets = [str componentsSeparatedByString:@":::"];
                if ([componenets count] == 3) {
                    NSString *type = componenets[0];
                    NSString *ip = componenets[1];
                    NSString *name = componenets[2];
                    
                    Contact *contact = [[[Contact alloc] init] autorelease];
                    contact.displayName = name;
                    contact.ipAddress = ip;

                    if ([type rangeOfString:kWebRtcAccept].location != NSNotFound){
                        //[self startTestCallToIp:ip];
                        [Call startTestCallToIp:contact.ipAddress];
                        [delegate callAccepted:contact];
                    } else if ([type rangeOfString:kWebRtcCall].location != NSNotFound){
                        [delegate callFromContact:contact];
                    } else if ([type rangeOfString:kWebRtcDecline].location != NSNotFound){
                        [delegate callDeclined:contact];
                    }
                
                }
            }
        } break;
            
        default:
            assert(NO);
            // fall through
        case NSStreamEventErrorOccurred:
            // fall through
        case NSStreamEventEndEncountered: {
            //[self setupForNewGame];
            [self setupForNewConnection];
        } break;
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if (![aNetService isEqual:self.registeredService]){
        Contact *contact = [[[Contact alloc] init] autorelease];
        contact.service = aNetService;
        [delegate contactDisconnected:contact];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if (![aNetService isEqual:self.registeredService]){
        Contact *contact = [[[Contact alloc] init] autorelease];
        contact.service = aNetService;
        [delegate contactConnected:contact];
    }
}

@end
