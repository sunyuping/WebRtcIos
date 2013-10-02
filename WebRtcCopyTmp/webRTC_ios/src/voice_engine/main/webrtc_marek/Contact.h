//
//  Contact.h
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CallState){
    CallStateNone,
    CallStateWaiting,
    CallStateConnected,
};

@interface Contact : NSObject

@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) NSNetService *service;
@property (nonatomic, assign) CallState activeCall;
@property (nonatomic, retain) NSString *ipAddress;

@end
