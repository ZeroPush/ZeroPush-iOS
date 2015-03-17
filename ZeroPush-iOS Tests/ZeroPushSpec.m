//
//  ZeroPushSpec.m
//  ZeroPush-iOS
//
//  Created by Stefan Natchev on 9/12/14.
//  Copyright (c) 2015 ZeroPush. All rights reserved.
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
    NSLog(@"Token registration failed");
}
-(void)subscribeDidFailWithError:(NSError *)error
{
    NSLog(@"subscribe failed");
}
-(void)unsubscribeDidFailWithError:(NSError *)error
{
    NSLog(@"unsubscribe failed");
}
-(void)setBadgeDidFailWithError:(NSError *)error
{
    NSLog(@"set badge failed");
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
    __block ZeroPush * zeroPush = nil;

    let(deviceToken, ^{
        return [NSData dataWithHexString:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"];
    });
    let(userDefaults, ^{
        return [NSUserDefaults standardUserDefaults];
    });

    beforeAll(^{
        [[LSNocilla sharedInstance] start];
    });

    beforeEach(^{
        zeroPush = [[ZeroPush alloc] init];
        zeroPush.delegate = application;
        zeroPush.apiKey = @"testing";
        [userDefaults removeObjectForKey:@"com.zeropush.api.deviceToken"];
    });

    afterAll(^{
        [[LSNocilla sharedInstance] stop];
    });
    afterEach(^{
        [[LSNocilla sharedInstance] clearStubs];
    });

    context(@"engageWithAPIKey", ^{
        it(@"should initialize the shared instance", ^{
            [ZeroPush engageWithAPIKey:@"testing"];
            [[[ZeroPush shared].apiKey should] equal:@"testing"];
        });
        it(@"should initialize the shared instance with a delegate", ^{
            id newDelegate = [[TestApplication alloc] init];
            [ZeroPush engageWithAPIKey:@"testing" delegate:newDelegate];
            [[(NSObject*)[ZeroPush shared].delegate should] equal:newDelegate];
            [[(NSObject*)[ZeroPush shared].delegate shouldNot] equal:application];
        });
        it(@"should not attempt to deference a deallocated delegate", ^{
            id newDelegate = [[TestApplication alloc] init];
            [ZeroPush engageWithAPIKey:@"testing" delegate:newDelegate];
            newDelegate = nil;  //dealloc
            [[(NSObject*)[ZeroPush shared].delegate should] beNil];
        });
    });

    context(@"deviceToken", ^{
        it(@"should never be nil", ^{
            [[zeroPush.deviceToken should] equal:@""];
        });

        it(@"should save to NSUserDefaults", ^{
            zeroPush.deviceToken = @"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
            [[[userDefaults stringForKey:@"com.zeropush.api.deviceToken"] should] equal:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"];
        });

        it(@"should retrieve from NSUserDefaults", ^{
            zeroPush.deviceToken = @"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
            zeroPush.deviceToken = nil;
            [[zeroPush.deviceToken should] equal:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"];
        });
    });

    context(@"API methods", ^{
        beforeEach(^{
            zeroPush.deviceToken = @"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
        });
        context(@"registerDeviceToken", ^{
            it(@"should register with a device token", ^{
                stubRequest(@"POST", @"https://api.zeropush.com/register").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");

                [zeroPush registerDeviceToken:deviceToken];
                [[[zeroPush deviceToken] should] equal:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"];
                [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
            });

            it(@"should register with a device token and subscribe it to a channel", ^{
                stubRequest(@"POST", @"https://api.zeropush.com/register").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel\":\"testing-channel\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");

                [zeroPush registerDeviceToken:deviceToken channel:@"testing-channel"];
                [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
            });

            it(@"should call the error selector if an error happens", ^{
                stubRequest(@"POST", @"https://api.zeropush.com/register").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}").
                andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);

                [zeroPush registerDeviceToken:deviceToken];
                [[expectFutureValue(application) shouldEventually] receive:@selector(tokenRegistrationDidFailWithError:)];
            });
        });

        context(@"subscribeToChannel", ^{
            it(@"should add a new channel to the channel subscriptions", ^{
                stubRequest(@"POST", @"https://api.zeropush.com/subscribe").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel\":\"player-1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
                [zeroPush subscribeToChannel:@"player-1"];
                [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
            });

            it(@"should call the error selector if an error occured", ^{
                stubRequest(@"POST", @"https://api.zeropush.com/subscribe").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel\":\"player-1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}").
                andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);
                [zeroPush subscribeToChannel:@"player-1"];
                [[expectFutureValue(application) shouldEventually] receive:@selector(subscribeDidFailWithError:)];
            });
        });

        context(@"unsubscribeFromChannel", ^{
            it(@"should remove a channel from the channel subscriptions", ^{
                stubRequest(@"DELETE", @"https://api.zeropush.com/subscribe").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel\":\"player-1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");

                [zeroPush unsubscribeFromChannel:@"player-1"];
                [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
            });

            it(@"should call the error selector if an error occured", ^{
                stubRequest(@"DELETE", @"https://api.zeropush.com/subscribe").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel\":\"player-1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}").
                andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);

                [zeroPush unsubscribeFromChannel:@"player-1"];
                [[expectFutureValue(application) shouldEventually] receive:@selector(unsubscribeDidFailWithError:)];
            });
        });

        context(@"unsubscribeFromAllChannels", ^{
            it(@"should remove all channels", ^{
                stubRequest(@"PUT", @"https://api.zeropush.com/devices/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel_list\":\"\"}");
                [zeroPush unsubscribeFromAllChannels];
                [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
            });

            it(@"should call the error selector if an error occured", ^{
                stubRequest(@"PUT", @"https://api.zeropush.com/devices/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel_list\":\"\"}").
                andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);

                [zeroPush unsubscribeFromAllChannels];
                [[expectFutureValue(application) shouldEventually] receive:@selector(unsubscribeDidFailWithError:)];
            });
        });

        context(@"getChannels", ^{
            it(@"should invoke the callback with the channels", ^{
                __block NSArray *fetchedChannels = nil;

                stubRequest(@"GET", @"https://api.zeropush.com/devices/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
                withHeaders(@{@"Authorization": @"Token token=\"testing\""}).
                andReturn(200).
                withBody(@"{\"channels\":[\"player-1\"]}");

                [zeroPush getChannels:^(NSArray *channels, NSError *error) {
                    fetchedChannels = channels;
                }];
                [[expectFutureValue(fetchedChannels) shouldEventually] equal:@[@"player-1"]];
            });

            it(@"should invoke the callback with an error", ^{
                __block NSArray *fetchedChannels = nil;
                __block NSError *requestError = nil;

                stubRequest(@"GET", @"https://api.zeropush.com/devices/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
                withHeaders(@{@"Authorization": @"Token token=\"testing\""}).
                andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);

                [zeroPush getChannels:^(NSArray *channels, NSError *error) {
                    fetchedChannels = channels;
                    requestError = error;
                }];
                [[expectFutureValue(fetchedChannels) shouldEventually] beNil];
                [[expectFutureValue(requestError) shouldEventually] beNonNil];
            });
        });

        context(@"setChannels", ^{
            it(@"should make a request to set channels", ^{
                stubRequest(@"PUT", @"https://api.zeropush.com/devices/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel_list\":\"player-1,game-12\"}");

                [zeroPush setChannels:@[@"player-1", @"game-12"]];
                [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
            });

            it(@"should call the error selector if an error occured", ^{
                stubRequest(@"PUT", @"https://api.zeropush.com/devices/1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"channel_list\":\"player-1,game-12\"}").
                andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);
                [zeroPush setChannels:@[@"player-1", @"game-12"]];
                [[expectFutureValue(application) shouldEventually] receive:@selector(subscribeDidFailWithError:)];
            });
        });

        context(@"setBadge", ^{
            it(@"should make a request to set badge", ^{
                stubRequest(@"POST", @"https://api.zeropush.com/set_badge").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"badge\":\"1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");

                [zeroPush setBadge:1];
                [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
            });

            it(@"should call the error selector if an error occured", ^{
                stubRequest(@"POST", @"https://api.zeropush.com/set_badge").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"badge\":\"1\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}").
                andFailWithError([NSError errorWithDomain:@"com.zeropush.api" code:401 userInfo:nil]);
                [zeroPush setBadge:1];
                [[expectFutureValue(application) shouldEventually] receive:@selector(setBadgeDidFailWithError:)];
            });
        });

        context(@"resetBadge", ^{
            it(@"should make a request to set the badge to 0", ^{
                stubRequest(@"POST", @"https://api.zeropush.com/set_badge").
                withHeaders(@{ @"Content-Type": @"application/json",
                               @"Authorization": @"Token token=\"testing\""}).
                withBody(@"{\"badge\":\"0\",\"device_token\":\"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\"}");
                [zeroPush resetBadge];
                [[expectFutureValue(zeroPush.lastResponse) shouldEventually] beNonNil];
            });
        });
    });
});

SPEC_END
