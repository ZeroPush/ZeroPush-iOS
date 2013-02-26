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

@end

@implementation ZeroPush

@synthesize apiKey = _apiKey;
@synthesize delegate = _delegate;

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

- (void)registerDeviceToken:(NSData *)deviceToken
{
    NSString *token = [ZeroPush deviceTokenFromData:deviceToken];
    NSString *registerURL = @"https://api.zeropush.com/register";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:token forKey:@"device_token"];
    [params setObject:self.apiKey forKey:@"auth_token"];
    NSData *postBody = [NSData formEncodedDataFor:params];
    NSMutableDictionary *requestOptions = [NSMutableDictionary dictionaryWithObject:postBody forKey:kSeriouslyBody];
    [Seriously post:registerURL options:requestOptions handler:^(id data, NSHTTPURLResponse *response, NSError *error)
    {
        NSInteger statusCode = [response statusCode];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ((statusCode > 201) && [self.delegate respondsToSelector:@selector(tokenRegistrationDidFailWithError:)])
        {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            if (json) {
                [userInfo setObject:json forKey:@"response_data"];
            }
            if (error) {
                [userInfo setObject:error forKey:@"response_error"];
            }
            [userInfo setObject:response forKey:@"response"];
            NSError *error = [NSError errorWithDomain:@"com.zeropush.api" code:statusCode userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
            [self.delegate tokenRegistrationDidFailWithError:error];
        }
    }];
}

@end
