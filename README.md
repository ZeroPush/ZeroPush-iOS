[![ZeroPush](https://raw.github.com/ZeroPush/ZeroPush-iOS/master/zeropush-docs-header.png)](https://zeropush.com)
[![ZeroPush Cocoapod](http://img.shields.io/cocoapods/v/ZeroPush.svg)](http://cocoapods.org/?q=zeropush)

Purpose:
---

ZeroPush-iOS is a lightweight Obj-C wrapper around the [ZeroPush](http://zeropush.com) API.
It provides some convenience methods to help you get up an running with ZeroPush as quickly as possible.

Building/Linking/Adding to your project:
---

We recommend using the [ZeroPush Cocoapod](http://cocoapods.org/?q=zeropush).

In your `Podfile` add the following line:

```ruby
pod 'ZeroPush', '~> 2.0'
```

and install the Pods
```bash
$> pod install
```

Configuration:
---

After the client library has been installed, add the following to your `AppDelegate`.

```objc
//In AppDelegate.h - Add the ZeroPushDelegate

#import "ZeroPush.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate, ZeroPushDelegate>


// In AppDelegate.m
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [ZeroPush engageWithAPIKey:@"your-zeropush-app-token" delegate:self];

    //now ask the user if they want to recieve push notifications. You can place this in another part of your app.
    [[ZeroPush shared] registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)tokenData
{
    // Call the convenience method registerDeviceToken, this helps us track device tokens for you
    [[ZeroPush shared] registerDeviceToken:tokenData];

    // This would be a good time to save the token and associate it with a user that you want to notify later.
    NSString *tokenString = [ZeroPush deviceTokenFromData:tokenData];
    NSLog(@"%@", tokenString);

    // For instance you can associate it with a user's email address
    // [[ZeroPush shared] subscribeToChannel:@"user@example.com"];
    // You can then use the /broadcast endpoint to notify all devices subscribed to that email address. No need to save tokens!
    // Don't forget to unsubscribe from the channel when the user logs out of your app!
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"%@", [error description]);
    //Common reason for errors:
    //  1.) Simulator does not support receiving push notifications
    //  2.) User rejected push alert
    //  3.) "no valid 'aps-environment' entitlement string found for application"
    //      This means your provisioning profile does not have Push Notifications configured. https://zeropush.com/documentation/generating_certificates
}

```

Upgrading from iOS7
---

If you were using the helper method `[[ZeroPush shared] registerForRemoteNotificationTypes:]` in iOS7, you will need to change it when deploying to iOS8

Before:
```
[[ZeroPush shared] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
```

After:
```
[[ZeroPush shared] registerForRemoteNotifications];
```

Documentation:
---

For more detailed documentation, refer to the [ZeroPush Docs](https://zeropush.com/documentation).

License:
---

Copyright (c) 2014 Symmetric Infinity LLC

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

