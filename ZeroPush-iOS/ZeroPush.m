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

static NSString *const ZeroPushAPIURLHost = @"https://api.zeropush.com";
//static NSString *const ZeroPushAPIURLHost = @"http://localhost:3000/api";

@interface ZeroPush ()

- (void)HTTPRequest:(NSString *) verb url:(NSString *)url params:(NSDictionary *)params completionHandler:(void (^)(NSHTTPURLResponse* response, NSData* data, NSError* connectionError)) handler;
- (void)HTTPRequest:(NSString *) verb url:(NSString *)url completionHandler:(void (^)(NSHTTPURLResponse* response, NSData* data, NSError* connectionError)) handler;

@end

@implementation ZeroPush

@synthesize apiKey = _apiKey;
@synthesize delegate = _delegate;
@synthesize deviceToken = _deviceToken;
@synthesize lastResponse = _lastResponse;

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

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    
    if (channel) {
        [params setObject:channel forKey:@"channel"];
    }
/*
    [self HTTPRequest:@"POST"
                  url:[self urlFromPath:@"register"]
               params:params
        errorSelector:@selector(tokenRegistrationDidFailWithError:)];
*/
    [self HTTPRequest:@"POST"
                  url:[self urlFromPath:@"register"]
               params:params
    completionHandler:^(NSHTTPURLResponse *response, NSData *data, NSError *connectionError) {
        NSLog(@"Here");
    }];
}

- (void)unregisterDeviceToken
{
    //[self performDeleteRequest:@"https://api.zeropush.com/" params:params errorSelector:<#(SEL)#>]
}

- (void)setBadge:(NSInteger)badge
{
    // reset the device's badge
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];

    // tell the api the badge has been reset
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:[NSString stringWithFormat:@"%ld", badge] forKey:@"badge"];

    [self HTTPRequest:@"POST"
                  url:[self urlFromPath:@"set_badge"]
               params:params
        errorSelector:@selector(setBadgeDidFailWithError:)];
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
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:channel forKey:@"channel"];

    [self HTTPRequest:@"POST"
                  url:[self urlFromPath:@"subscribe"]
               params:params
        errorSelector:@selector(subscribeDidFailWithError:)];
}

- (void)unsubscribeFromChannel:(NSString *)channel;
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:channel forKey:@"channel"];

    [self HTTPRequest:@"DELETE" url:[self urlFromPath:@"subscribe"]
               params:params
        errorSelector:@selector(unsubscribeDidFailWithError:)];
}

/*
- (NSArray *)channels
{
    NSString *url = @"https://api.zeropush.com/device/{device_token}";
}

-(void)setChannels:(NSArray *)channels
{
}

-(void)unsubscribeFromAllChannels
{
}
*/

#pragma mark - HTTP Requests

-(void)HTTPRequest:(NSString *) verb url:(NSString *)url params:(NSDictionary *)params completionHandler:(void (^)(NSHTTPURLResponse* response, NSData* data, NSError* connectionError)) handler
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = verb;

    if (params != nil)
    {
        NSError *error;
        NSData *json = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        request.HTTPBody = json;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }

    //NOTE: Consider queue
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *urlResponse, NSData *data, NSError *error) {
                               //call the handler, but remember to save the lastResponse
                               self.lastResponse = (NSHTTPURLResponse *) urlResponse;
                               handler(self.lastResponse, data, error);
                           }];
}

-(void)HTTPRequest:(NSString *)verb url:(NSString *)url completionHandler:(void (^)(NSHTTPURLResponse *, NSData *, NSError *))handler
{
    [self HTTPRequest:verb url:url params:nil completionHandler:handler];
}

-(void)HTTPRequest:(NSString *)verb url:(NSString *)url params:(NSDictionary *)params errorSelector:(SEL)errorSelector
{
    [self HTTPRequest:verb url:url params:params completionHandler:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        
        if (![self.delegate respondsToSelector:errorSelector]) {
            return;
        }
        if (error) {
            [self.delegate performSelector:errorSelector withObject:error];
            return;
        }
        NSInteger statusCode = [response statusCode];
        if (statusCode >= 400) {
            NSDictionary *userInfo = [self userInfoForData:data andResponse:response];
            NSError *apiError = [NSError errorWithDomain:@"com.zeropush.api" code:statusCode userInfo:userInfo];
            [self.delegate performSelector:errorSelector withObject:apiError];
        }
    }];
}

-(NSString *) urlFromPath:(NSString*) path
{
    return [NSString stringWithFormat:@"%@/%@", ZeroPushAPIURLHost, path];
}
@end
