//
//  ContactCallDelegate.h
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import <Foundation/Foundation.h>

@class Contact;

@protocol ContactCallDelegate <NSObject>

/**
 * Called when there is incomming call from contact
 * temporarily not working correctly
 */
- (void)callFromContact:(Contact*)contact;

/**
 * Called when contact declined our call
 */
- (void)callDeclined:(Contact*)contact;

/**
 * Called when contact accepted our call
 */
- (void)callAccepted:(Contact*)contact;

/**
 * Called when call is ended
 */
- (void)callEnded:(Contact*)contact;

/**
 * Called when contact becomes online
 */
- (void)contactConnected:(Contact*)contact;

/**
 *  Called when contacts becomes offline
 */
- (void)contactDisconnected:(Contact*)contact;


- (void)removeAllContacts;

@end
