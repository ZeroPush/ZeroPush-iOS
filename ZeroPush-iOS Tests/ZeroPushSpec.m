//
//  ZeroPushSpec.m
//  ZeroPush-iOS
//
//  Created by Stefan Natchev on 9/12/14.
//  Copyright (c) 2014 ZeroPush. All rights reserved.
//

#import "Kiwi.h"
#import "Nocilla.h"
#import "ZeroPush.h"

@interface TestApplication : NSObject<ZeroPushDelegate>
- (void)tokenRegistrationDidFailWithError:(NSError *)error;
- (void)subscribeDidFailWithError:(NSError *)error;
- (void)unsubscribeDidFailWithError:(NSError *)error;
- (void)setBadgeDidFailWithError:(NSError *)error;
@end

@implementation TestApplication
-(void)tokenRegistrationDidFailWithError:(NSError *)error
{
    NSLog(@"Token failed");
}
@end

//move this into a helper
@implementation NSData (HexString)

// Not efficent
+(id)dataWithHexString:(NSString *)hex
{
	char buf[3];
	buf[2] = '\0';
	NSAssert(0 == [hex length] % 2, @"Hex strings should have an even number of digits (%@)", hex);
	unsigned char *bytes = malloc([hex length]/2);
	unsigned char *bp = bytes;
	for (CFIndex i = 0; i < [hex length]; i += 2) {
		buf[0] = [hex characterAtIndex:i];
		buf[1] = [hex characterAtIndex:i+1];
		char *b2 = NULL;
		*bp++ = strtol(buf, &b2, 16);
		NSAssert(b2 == buf + 2, @"String should be all hex digits: %@ (bad digit around %ld)", hex, i);
	}
	
	return [NSData dataWithBytesNoCopy:bytes length:[hex length]/2 freeWhenDone:YES];
}

@end


SPEC_BEGIN(ZeroPushSpec)

describe(@"ZeroPush", ^{
    
    let(application, ^{
        return [[TestApplication alloc] init];
    });
    let(deviceToken, ^{
        return [NSData dataWithHexString:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"];
    });
    let(zeroPush, ^{
        return [ZeroPush shared];
    });
    
    beforeAll(^{
        [ZeroPush engageWithAPIKey:@"testing" delegate:application];
//        [[LSNocilla sharedInstance] start];
    });
    
    afterAll(^{
//        [[LSNocilla sharedInstance] stop];
    });
    afterEach(^{
//        [[LSNocilla sharedInstance] clearStubs];
    });
    
    //context(@"registerForRemoteNotifications");

    context(@"registerDeviceToken", ^{
        it(@"should register with a device token", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/register").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
            
            [zeroPush registerDeviceToken:deviceToken];
            [[[zeroPush deviceToken] should] equal:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"];
            [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];

        });
        
        it(@"should register with a device token and subscribe it to a channel", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/register").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"channel\":\"testing-channel\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
            
            [zeroPush registerDeviceToken:deviceToken channel:@"testing-channel"];
            [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
        });

        it(@"should call the error selector if an error happens", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/register").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}").
            andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);
            
            [zeroPush registerDeviceToken:deviceToken];
            [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
        });
    });
/*
    context(@"unregisterDeviceToken");
    
    context(@"subscribeToChannl");
    context(@"unsubscribeFromChannel");
    context(@"unsubscribeFromAllChannels");
    context(@"channels");
    context(@"setChannels");
    
    context(@"setBadge");
    context(@"resetBadge");
    
    context(@"error callbacks");
*/
});

SPEC_END
