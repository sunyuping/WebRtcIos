//
//  CallManager.h
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import <Foundation/Foundation.h>

@protocol ContactCallDelegate;

@interface CallManager : NSObject

+ (CallManager*)sharedInstance;

@property (nonatomic, assign) id <ContactCallDelegate> delegate;

- (void)start;
- (void)call:(Contact*)contact;
- (void)acceptCallFrom:(Contact*)contact;
- (void)declineCallFrom:(Contact*)contact;

@end
