//
//  ZeroPush_iOS_SDK.m
//  ZeroPush-iOS-SDK
//
//  Created by Stefan Natchev on 2/5/13.
//  Copyright (c) 2013 zeropush. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "ZeroPush.h"

@interface ZeroPush ()

@property AFHTTPClient *httpClient;

@end

@implementation ZeroPush
@synthesize httpClient;

+(ZeroPush *)shared
{
    static ZeroPush *shared;
    @synchronized(self)
    {
        if(!shared) {
            shared = [[ZeroPush alloc] init];
        }
        return shared;
    }
}

-(id) init
{
    if ((self = [super init]))
    {
        NSURL *baseURL = [NSURL URLWithString:@"https://zeropush.com/api"];
        self.httpClient = [AFHTTPClient clientWithBaseURL:baseURL];
    }
    return self;
}

@end
