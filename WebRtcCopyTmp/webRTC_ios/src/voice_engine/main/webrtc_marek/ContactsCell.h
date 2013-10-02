//
//  ContactsCell.h
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import <UIKit/UIKit.h>

extern NSString *const kContactsCellReusableIdentifier;

@class Contact;
@interface ContactsCell : UITableViewCell

@property (nonatomic, retain) Contact *contact;

@end
