//
//  main.m
//  hookflash
//
//  Created by Vladimir Morosev on 11-10-08.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]){
    int returnCode = 0;
    @autoreleasepool {
        @try{
#if 1
            returnCode = UIApplicationMain(argc, argv, nil, @"MarekAppDelegate");
#else
            returnCode = UIApplicationMain(argc, argv, nil, @"hookflashAppDelegate");
#endif
        } @catch (NSException* exception) {
            NSLog(@"Uncaught exception: %@", exception.description);
            NSLog(@"Stack trace: %@", [exception callStackSymbols]);
        }
    }
    return returnCode;
}
