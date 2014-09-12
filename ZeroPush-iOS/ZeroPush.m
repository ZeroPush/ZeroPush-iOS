//
//  ZeroPush.m
//  ZeroPush-iOS
//
//  Created by Stefan Natchev on 2/5/13.
//  Copyright (c) 2014 SymmetricInfinity. All rights reserved.
//

#import "ZeroPush.h"
#import "Seriously.h"
#import "NSData+FormEncoding.h"

@implementation ZeroPush

@synthesize apiKey = _apiKey;
@synthesize delegate = _delegate;
@synthesize deviceToken = _deviceToken;

+ (ZeroPush *)shared
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)engageWithAPIKey:(NSString *)apiKey
{
    [self engageWithAPIKey:apiKey delegate:nil];
}

+ (void)engageWithAPIKey:(NSString *)apiKey delegate:(id<ZeroPushDelegate>)delegate
{
    ZeroPush *sharedInstance = [ZeroPush shared];
    sharedInstance.apiKey = apiKey;
    sharedInstance.delegate = delegate;
}

+ (NSString *)deviceTokenFromData:(NSData *)tokenData
{
    NSString *token = [tokenData description];
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    return token;
}

- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
}

- (void)registerForRemoteNotifications
{
#ifndef __IPHONE_7_0
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                           UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound)];
#endif

#ifdef __IPHONE_8_0
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

- (NSDictionary *)userInfoForData:(id)data andResponse:(NSHTTPURLResponse *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (data) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        json = json == nil ? [NSNull null] : json;
        [userInfo setObject:json forKey:@"response_data"];
    }
    if (response) {
        [userInfo setObject:response forKey:@"response"];
    }
    // make sure not to return a mutable dictionary
    return [NSDictionary dictionaryWithDictionary:userInfo];
}

- (void)registerDeviceToken:(NSData *)deviceToken
{
    [self registerDeviceToken:deviceToken channel:nil];
}

- (void)registerDeviceToken:(NSData *)deviceToken channel:(NSString *)channel
{
    self.deviceToken = [ZeroPush deviceTokenFromData:deviceToken];
    NSString *url = @"https://api.zeropush.com/register";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    if (channel) {
        [params setObject:channel forKey:@"channel"];
    }
    [self performPostRequest:url params:params errorSelector:@selector(tokenRegistrationDidFailWithError:)];
}

{
}


- (void)setBadge:(NSInteger)badge
{
    // reset the device's badge
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];

    // tell the api the badge has been reset
    NSString *url = @"https://api.zeropush.com/set_badge";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:[NSString stringWithFormat:@"%d", badge] forKey:@"badge"];
    [self performPostRequest:url params:params errorSelector:@selector(setBadgeDidFailWithError:)];
}

- (void)resetBadge
{
    if (_deviceToken == nil) {
        return;
    }
    [self setBadge:0];
}

- (NSString *)deviceToken
{
    if (_deviceToken == nil) {
        return @"";
    }
    return _deviceToken;
}

#pragma mark - Channels

- (void)subscribeToChannel:(NSString *)channel;
{
    NSString *url = @"https://api.zeropush.com/subscribe";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:channel forKey:@"channel"];
    [self performPostRequest:url params:params errorSelector:@selector(subscribeDidFailWithError:)];
}

- (void)unsubscribeFromChannel:(NSString *)channel;
{
    NSString *url = @"https://api.zeropush.com/subscribe";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:channel forKey:@"channel"];
    [self performDeleteRequest:url params:params errorSelector:@selector(unsubscribeDidFailWithError:)];
}

- (void)performPostRequest:(NSString *)url params:(NSDictionary *)params errorSelector:(SEL)errorSelector
{
    NSData *postBody = [NSData formEncodedDataFor:params];
    NSMutableDictionary *requestOptions = [NSMutableDictionary dictionaryWithObject:postBody forKey:kSeriouslyBody];
    [Seriously post:url options:requestOptions handler:^(id data, NSHTTPURLResponse *response, NSError *error)
     {
         if (![self.delegate respondsToSelector:errorSelector]) {
             return;
         }
         if (error) {
             [self.delegate performSelector:errorSelector withObject:error];
             return;
         }
         NSInteger statusCode = [response statusCode];
         if (statusCode > 201) {
             NSDictionary *userInfo = [self userInfoForData:data andResponse:response];
             NSError *apiError = [NSError errorWithDomain:@"com.zeropush.api" code:statusCode userInfo:userInfo];
             [self.delegate performSelector:errorSelector withObject:apiError];
         }
     }];

}

{
}

@end
