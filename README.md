[![ZeroPush](https://raw.github.com/SymmetricInfinity/ZeroPush-iOS/master/zeropush-docs-header.png)](https://zeropush.com)

Purpose:
---

ZeroPush-iOS is a lightweight Obj-C wrapper around the [ZeroPush](http://zeropush.com) API.
It provides some convenience methods to help you get up an running with ZeroPush as quickly as possible.

Building/Linking/Adding to your project:
---

We recommend using the [ZeroPush Cocoapod](http://cocoapods.org/?q=zeropush).

In your `Podfile` add the following line:

```ruby
pod 'ZeroPush', '~> 1.1.0'
```

and install the Pods
```bash
$> pod install
```

Configuration
---

After the client library has been installed, add the following to your `AppDelegate`.

```objc
// In your application delegate
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [ZeroPush engageWithAPIKey:@"your-zeropush-auth-token" delegate:self];
    [[ZeroPush shared] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                           UIRemoteNotificationTypeBadge |
                                                           UIRemoteNotificationTypeSound)];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)tokenData
{
    // Call the convenience method registerDeviceToken, this helps us track device tokens for you
    [[ZeroPush shared] registerDeviceToken:tokenData];

    // This would be a good time to save the token and associate it with a user that you want to notify later.
    NSString *tokenString = [ZeroPush deviceTokenFromData:tokenData];
    NSLog(@"%@", tokenString);
}
```

Dependencies:
---

ZeroPush-iOS depends on

NSData+FormEncoding.h and Seriously.h

from [ADiOSUtilities](https://github.com/adamvduke/ADiOSUtilities) and [seriously](https://github.com/probablycorey/seriously) respectively

Documentation
---

For more detailed documentation, refer to the [ZeroPush Docs](https://zeropush.com/documentation).

