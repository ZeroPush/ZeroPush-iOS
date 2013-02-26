//
//  ZeroPush.h
//  ZeroPush-iOS
//
//  Created by Stefan Natchev on 2/5/13.
//  Copyright (c) 2013 SymmetricInfinity. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZeroPushDelegate <NSObject>
@optional

- (void)tokenRegistrationDidFailWithError:(NSError *)error;

@end

@interface ZeroPush : NSObject

@property (nonatomic, assign) id<ZeroPushDelegate> delegate;

+ (ZeroPush*) shared;

+ (void)engageWithAPIKey:(NSString *)apiKey;

+ (void)engageWithAPIKey:(NSString *)apiKey delegate:(id<ZeroPushDelegate>)delegate;

+ (NSString *)deviceTokenFromData:(NSData *)tokenData;

- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

- (void)registerDeviceToken:(NSData *) deviceToken;

@end
