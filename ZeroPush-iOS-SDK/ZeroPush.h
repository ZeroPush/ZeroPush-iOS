//
//  ZeroPush_iOS_SDK.h
//  ZeroPush-iOS-SDK
//
//  Created by Stefan Natchev on 2/5/13.
//  Copyright (c) 2013 zeropush. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZeroPush : NSObject

+(ZeroPush*) shared;
-(void) configureWithURL:(NSURL*) zeroPushURL;
-(void) registerForRemoteNotifications;
-(void) registerDeviceToken:(NSData*) deviceToken;
-(void) handleNotification:(NSDictionary*) info;
-(void) resetBadge;
@end
