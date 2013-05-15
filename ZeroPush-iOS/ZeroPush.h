//
//  ZeroPush.h
//  ZeroPush-iOS
//
//  Created by Stefan Natchev on 2/5/13.
//  Copyright (c) 2013 SymmetricInfinity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol ZeroPushDelegate <NSObject>
@optional

- (void)tokenRegistrationDidFailWithError:(NSError *)error;

@end

@interface ZeroPush : NSObject

@property (nonatomic, assign) id<ZeroPushDelegate> delegate;

/**
 * Get the shared ZeroPush instance
 */
+ (ZeroPush *) shared;

/**
 * Set the shared ZeroPush instance's apiKey
 */
+ (void)engageWithAPIKey:(NSString *)apiKey;

/**
 * Set the shared ZeroPush instance's apiKey and specify a ZeroPushDelegate
 */
+ (void)engageWithAPIKey:(NSString *)apiKey delegate:(id<ZeroPushDelegate>)delegate;

/**
 * Parse a device token given the raw data returned by Apple from registering for notifications
 */
+ (NSString *)deviceTokenFromData:(NSData *)tokenData;

/**
 * A convenience wrapper for [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
 */
- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

/**
 * Register the device's token with ZeroPush
 */
- (void)registerDeviceToken:(NSData *) deviceToken;

/**
 * Set the device's badge number to the given value
 */
- (void)setBadge:(NSInteger)badge;

/**
 * Set the device's badge number to zero
 */
- (void)resetBadge;

@end
