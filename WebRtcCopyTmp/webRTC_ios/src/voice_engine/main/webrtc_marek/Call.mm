//
//  CallManager+TestCall.m
//  voice_engine_ios
//
//  Created by Marek Kotewicz on 02.10.2013.
//
//

#import "Call.h"

namespace voetest{
    int hookflash_test(const char* directory, int testID, const char* sndIpAddress, int sndPort, int rcvPort);
};


@implementation Call

+ (IBAction)startTestCallToIp:(NSString*)ip{
    NSString* documents = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
    
    const char* buffer = [documents UTF8String];
    const char* sendIPAddress = [ip UTF8String];
    int sendPort = 20000;
    int receivePort = 20000;
    
    voetest::hookflash_test(buffer, 0, sendIPAddress, sendPort, receivePort);
}



@end
