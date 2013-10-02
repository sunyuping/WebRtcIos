//
//  ContactsCell.m
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import "ContactsCell.h"
#import "Contact.h"

NSString *const kContactsCellReusableIdentifier = @"ContactsCell";

@interface ContactsCell (){
    IBOutlet UILabel *nameLabel;
    IBOutlet UIActivityIndicatorView *activeCallIndicator;
}

@end

@implementation ContactsCell
@synthesize contact;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]){
        [self.contentView setBackgroundColor:RGB(30, 30, 30, 1)];
        UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 66)] autorelease];
        [view setBackgroundColor:RGB(23, 23, 23, 1)];
        [self setSelectedBackgroundView:view];
        
        view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 66)] autorelease];
        [view setBackgroundColor:[UIColor lightGrayColor]];
        [self setBackgroundView:view];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews{
    [super layoutSubviews];

    switch (contact.activeCall) {
        case CallStateWaiting:
            self.backgroundView.backgroundColor = [UIColor yellowColor];
            [activeCallIndicator startAnimating];
            activeCallIndicator.hidden = NO;
            break;
            
        case CallStateConnected:
            self.backgroundView.backgroundColor = [UIColor greenColor];
            [activeCallIndicator stopAnimating];
            activeCallIndicator.hidden = YES;
            break;
            
        case CallStateNone:
        default:
            self.backgroundView.backgroundColor = [UIColor lightGrayColor];
            [activeCallIndicator stopAnimating];
            activeCallIndicator.hidden = YES;
            break;
    }
    
    nameLabel.text = contact.displayName;
}

- (void)dealloc {
    [nameLabel release];
    [activeCallIndicator release];
    self.contact = nil;
    [super dealloc];
}
@end
