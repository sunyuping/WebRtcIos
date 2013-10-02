//
//  Contact.m
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import "Contact.h"

@implementation Contact
@synthesize service, displayName, activeCall, ipAddress;

- (void)dealloc{
    self.displayName = nil;
    self.service = nil;
    self.ipAddress = nil;
    [super dealloc];
}

- (void)setService:(NSNetService *)ser{
    [service release];
    service = [ser retain];
    self.displayName = [service name];
}

@end
