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

/* NSData category */
//  NSData+HexString.m
//  libsecurity_transform
//
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//
@implementation NSData (HexString)

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

/* ZeroPush TestMethods */

@interface ZeroPush (TestMethods)

@property (nonatomic, strong)NSHTTPURLResponse *lastResponse;

@end

SPEC_BEGIN(ZeroPushSpec)

describe(@"ZeroPush", ^{
    __block id application = [[TestApplication alloc] init];

    let(deviceToken, ^{
        return [NSData dataWithHexString:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"];
    });

    beforeAll(^{
        [ZeroPush engageWithAPIKey:@"testing" delegate:application];
        [[LSNocilla sharedInstance] start];
    });

    afterAll(^{
        [[LSNocilla sharedInstance] stop];
    });
    afterEach(^{
        [[LSNocilla sharedInstance] clearStubs];
    });

    //context(@"registerForRemoteNotifications");

    context(@"registerDeviceToken", ^{
        it(@"should register with a device token", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/register").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
            
            [[ZeroPush shared] registerDeviceToken:deviceToken];
            [[[[ZeroPush shared] deviceToken] should] equal:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"];
            [[expectFutureValue([ZeroPush shared].lastResponse) shouldEventually] beNonNil];
        });

        it(@"should register with a device token and subscribe it to a channel", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/register").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"channel\":\"testing-channel\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
            
            [[ZeroPush shared] registerDeviceToken:deviceToken channel:@"testing-channel"];
            [[expectFutureValue([ZeroPush shared].lastResponse) shouldEventually] beNonNil];
        });

        it(@"should call the error selector if an error happens", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/register").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}").
            andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);

            [[ZeroPush shared] registerDeviceToken:deviceToken];
            [[expectFutureValue(application) shouldEventually] receive:@selector(tokenRegistrationDidFailWithError:)];
        });
    });
     
    context(@"subscribeToChannel", ^{
        it(@"should add a new channel to the channel subscriptions", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/subscribe").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"channel\":\"player-1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
            [[ZeroPush shared] subscribeToChannel:@"player-1"];
            [[expectFutureValue([ZeroPush shared].lastResponse) shouldEventually] beNonNil];
        });
    });
    
    context(@"unsubscribeFromChannel", ^{
        it(@"should remove a channel from the channel subscriptions", ^{
            stubRequest(@"DELETE", @"https://api.zeropush.com/subscribe").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"channel\":\"player-1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
            
            [[ZeroPush shared] unsubscribeFromChannel:@"player-1"];
            [[expectFutureValue([ZeroPush shared].lastResponse) shouldEventually] beNonNil];
        });
    });
    
    context(@"unsubscribeFromAllChannels", ^{
        it(@"should remove all channels", ^{
            stubRequest(@"PUT", @"https://api.zeropush.com/device/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"channel_list\":\"\",\"auth_token\":\"testing\"}");
            [[ZeroPush shared] unsubscribeFromAllChannels];
            [[expectFutureValue([ZeroPush shared].lastResponse) shouldEventually] beNonNil];
        });
    });

    context(@"getChannels", ^{
        it(@"should invoke the callback with the channels", ^{
            __block NSArray *fetchedChannels = nil;

            stubRequest(@"GET", @"https://api.zeropush.com/device/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\"}").
            andReturn(200).
            withBody(@"{\"channels\":[\"player-1\"]}");

            [[ZeroPush shared] getChannels:^(NSArray *channels, NSError *error) {
                fetchedChannels = channels;
            }];

            [[expectFutureValue(fetchedChannels) shouldEventually] haveCountOf:1];
        });
//        it(@"should invoke the callback with an error");
    });
    
    context(@"setChannels", ^{
        it(@"should make a request to set channels", ^{
            stubRequest(@"PUT", @"https://api.zeropush.com/device/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"channel_list\":\"player-1,game-12\",\"auth_token\":\"testing\"}");

            [[ZeroPush shared] setChannels:@[@"player-1", @"game-12"]];
            [[expectFutureValue([ZeroPush shared].lastResponse) shouldEventually] beNonNil];
        });
    });
    
    context(@"setBadge", ^{
        it(@"should make a request to set badge", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/set_badge").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"badge\":\"1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");

            [[ZeroPush shared] setBadge:1];
            [[expectFutureValue([ZeroPush shared].lastResponse) shouldEventually] beNonNil];
        });
    });

    context(@"resetBadge", ^{
        it(@"should make a request to set the badge to 0", ^{
            stubRequest(@"POST", @"https://api.zeropush.com/set_badge").
            withHeaders(@{ @"Content-Type": @"application/json" }).
            withBody(@"{\"auth_token\":\"testing\",\"badge\":\"0\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
            [[ZeroPush shared] resetBadge];
            [[expectFutureValue([ZeroPush shared].lastResponse) shouldEventually] beNonNil];
        });
    });

    /*
    context(@"verifyCredentials", ^{
        it(@"should verify the credentials of the token", ^{
            [[[[ZeroPush shared] verifyCredentials] should] beTrue];
        });
    });
     */
});

SPEC_END
