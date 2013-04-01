//
//  ZeroPush.m
//  ZeroPush-iOS
//
//  Created by Stefan Natchev on 2/5/13.
//  Copyright (c) 2013 SymmetricInfinity. All rights reserved.
//

#import "ZeroPush.h"
#import "Seriously.h"
#import "NSData+FormEncoding.h"

@interface ZeroPush ()

@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, strong)NSString *deviceToken;

@end

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
    //TODO: possibly hang on to the types
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
}

- (BOOL)shouldNotifyRegistrationError
{
    SEL registrationFailedSelector = @selector(tokenRegistrationDidFailWithError:);
    return [self.delegate respondsToSelector:registrationFailedSelector];
}

- (void)notifyRegistrationError:(NSError *)error
{
    BOOL shouldNotifyDelegate = [self shouldNotifyRegistrationError];
    if (error && shouldNotifyDelegate)
    {
        [self.delegate tokenRegistrationDidFailWithError:error];
    }
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
    self.deviceToken = [ZeroPush deviceTokenFromData:deviceToken];
    NSString *registerURL = @"https://api.zeropush.com/register";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.deviceToken forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    NSData *postBody = [NSData formEncodedDataFor:params];
    NSMutableDictionary *requestOptions = [NSMutableDictionary dictionaryWithObject:postBody forKey:kSeriouslyBody];
    [Seriously post:registerURL options:requestOptions handler:^(id data, NSHTTPURLResponse *response, NSError *error)
    {
        if (error) {
            [self notifyRegistrationError:error];
            return;
        }
        NSInteger statusCode = [response statusCode];
        if (statusCode > 201) {
            NSDictionary *userInfo = [self userInfoForData:data andResponse:response];
            NSError *apiError = [NSError errorWithDomain:@"com.zeropush.api" code:statusCode userInfo:userInfo];
            [self notifyRegistrationError:apiError];
        }
    }];
}

-(void)resetBadge
{
    // reset the device's badge
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

    // tell the api the badge has been reset
    if (self.deviceToken) {
        NSString *registerURL = @"https://api.zeropush.com/reset_badge";
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:self.deviceToken forKey:@"device_token"];
        [params setObject:self.apiKey forKey:@"auth_token"];
        NSData *postBody = [NSData formEncodedDataFor:params];
        NSMutableDictionary *requestOptions = [NSMutableDictionary dictionaryWithObject:postBody forKey:kSeriouslyBody];
        [Seriously post:registerURL options:requestOptions handler:^(id data, NSHTTPURLResponse *response, NSError *error)
        {
            if (error) {
                NSLog(@"ZeroPush experienced an error resetting the device's badge.");
                return;
            }
        }];
    }
}

@end
