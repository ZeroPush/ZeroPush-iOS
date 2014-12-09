//
//  ZeroPush.m
//  ZeroPush-iOS
//
//  Created by Stefan Natchev on 2/5/13.
//  Copyright (c) 2014 SymmetricInfinity. All rights reserved.
//

#import "ZeroPush.h"

static NSString *const ZeroPushAPIURLHost = @"https://api.zeropush.com";
static NSString *const ZeroPushClientVersion = @"ZeroPush-iOS/2.0.4";

@interface ZeroPush ()

@property (nonatomic, strong)NSHTTPURLResponse *lastResponse;
@property (nonatomic, strong)NSOperationQueue *operationQueue;

- (void)HTTPRequest:(NSString *) verb url:(NSString *)url params:(NSDictionary *)params completionHandler:(void (^)(NSHTTPURLResponse* response, NSData* data, NSError* connectionError)) handler;
- (void)HTTPRequest:(NSString *) verb url:(NSString *)url completionHandler:(void (^)(NSHTTPURLResponse* response, NSData* data, NSError* connectionError)) handler;
- (void)HTTPRequest:(NSString *) verb url:(NSString *)url params:(NSDictionary *)params errorSelector:(SEL)errorSelector;
@end

@implementation ZeroPush

@synthesize apiKey = _apiKey;
@synthesize delegate = _delegate;
@synthesize deviceToken = _deviceToken;
@synthesize lastResponse = _lastResponse;
@synthesize operationQueue = _operationQueue;

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

-(id)init {
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }

    return self;
}

- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
}

- (void)registerForRemoteNotifications
{
#ifdef __IPHONE_8_0
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
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

    NSString *url = [NSString stringWithFormat:@"%@/register", ZeroPushAPIURLHost];

    [self HTTPRequest:@"POST"
                  url:url
               params:params
        errorSelector:@selector(tokenRegistrationDidFailWithError:)];
}

- (NSString *)deviceToken
{
    if (_deviceToken == nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _deviceToken = [defaults stringForKey:@"com.zeropush.api.deviceToken"];
    }

    if (_deviceToken == nil) {
        return @"";
    }

    return _deviceToken;
}

- (void)setDeviceToken:(NSString *)deviceToken
{
    if (deviceToken != nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:deviceToken forKey:@"com.zeropush.api.deviceToken"];
        [defaults synchronize];
    }
    _deviceToken = deviceToken;
}

-(NSString *)apiKey
{
    if (_apiKey == nil) {
        return @"";
    }
    return _apiKey;
}


- (void)setBadge:(NSInteger)badge
{
    // reset the device's badge
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];

    // tell the api the badge has been reset
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:[NSString stringWithFormat:@"%ld", (long)badge] forKey:@"badge"];

    NSString *url = [NSString stringWithFormat:@"%@/set_badge", ZeroPushAPIURLHost];

    [self HTTPRequest:@"POST"
                  url:url
               params:params
        errorSelector:@selector(setBadgeDidFailWithError:)];
}

- (void)resetBadge
{
    [self setBadge:0];
}

- (void)subscribeToChannel:(NSString *)channel;
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:channel forKey:@"channel"];

    NSString *url = [NSString stringWithFormat:@"%@/subscribe", ZeroPushAPIURLHost];

    [self HTTPRequest:@"POST"
                  url:url
               params:params
        errorSelector:@selector(subscribeDidFailWithError:)];
}

- (void)unsubscribeFromChannel:(NSString *)channel;
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    [params setObject:channel forKey:@"channel"];

    NSString *url = [NSString stringWithFormat:@"%@/subscribe", ZeroPushAPIURLHost];

    [self HTTPRequest:@"DELETE"
                  url:url
               params:params
        errorSelector:@selector(unsubscribeDidFailWithError:)];
}

-(void)unsubscribeFromAllChannels
{
    NSString *url = [NSString stringWithFormat:@"%@/devices/%@", ZeroPushAPIURLHost, self.deviceToken];

    [self HTTPRequest:@"PUT"
                  url:url
               params:@{@"auth_token": self.apiKey, @"channel_list": @""}
        errorSelector:@selector(unsubscribeDidFailWithError:)];
}

- (void)getChannels:(void (^)(NSArray *channels, NSError *error)) callback
{
    NSString *url = [NSString stringWithFormat:@"%@/devices/%@", ZeroPushAPIURLHost, self.deviceToken];

    [self HTTPRequest:@"GET"
                  url:url
               params:@{@"auth_token": self.apiKey}
    completionHandler:^(NSHTTPURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError) {
            return callback(nil, connectionError);
        }

        NSError *error;
        NSArray *channels = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        callback(channels, error);
    }];
}

-(void)setChannels:(NSArray *)channels
{
    NSString *url = [NSString stringWithFormat:@"%@/devices/%@", ZeroPushAPIURLHost, self.deviceToken];

    [self HTTPRequest:@"PUT"
                  url:url
               params:@{@"auth_token": self.apiKey, @"channel_list": [channels componentsJoinedByString:@","]}
        errorSelector:@selector(subscribeDidFailWithError:)];
}


#pragma mark - HTTP Requests

-(void)HTTPRequest:(NSString *) verb url:(NSString *)url params:(NSDictionary *)params completionHandler:(void (^)(NSHTTPURLResponse* response, NSData* data, NSError* connectionError)) handler
{
    self.lastResponse = nil;    //clear out the response

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = verb;

    if (params != nil)
    {
        NSError *jsonError;
        NSData *json = [NSJSONSerialization dataWithJSONObject:params options:0 error:&jsonError];

        if(jsonError) {
            return handler(nil, nil, jsonError);
        }

        request.HTTPBody = json;
        [request setValue:ZeroPushClientVersion forHTTPHeaderField:@"X-API-Client-Agent"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *urlResponse, NSData *data, NSError *error) {
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) urlResponse;
                               handler(httpResponse, data, error);
                               self.lastResponse = httpResponse;
                           }];
}

-(void)HTTPRequest:(NSString *)verb url:(NSString *)url completionHandler:(void (^)(NSHTTPURLResponse *, NSData *, NSError *))handler
{
    [self HTTPRequest:verb url:url params:nil completionHandler:handler];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
-(void)HTTPRequest:(NSString *)verb url:(NSString *)url params:(NSDictionary *)params errorSelector:(SEL)errorSelector
{
    [self HTTPRequest:verb url:url params:params completionHandler:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {

        if (![self.delegate respondsToSelector:errorSelector]) {
            NSLog(@"ZeroPush-iOS: %@", [error description]);
            return;
        }
        if (error) {
            [self.delegate performSelector:errorSelector withObject:error];
            return;
        }
        NSInteger statusCode = [response statusCode];

        //if 300, we need to manually follow redirects
        
        if (statusCode >= 400) {
            NSDictionary *userInfo = [self userInfoForData:data andResponse:response];
            NSError *apiError = [NSError errorWithDomain:@"com.zeropush.api" code:statusCode userInfo:userInfo];
            [self.delegate performSelector:errorSelector withObject:apiError];
        }
    }];
}
#pragma clang diagnostic pop
@end
