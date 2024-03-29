//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "MainAppContext.h"
#import "Signal-Swift.h"
#import <SignalCoreKit/Threading.h>
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSProfileManager.h>
#import <SignalMessaging/SignalMessaging-Swift.h>
#import <SignalServiceKit/OWSIdentityManager.h>
#import "SignalApp.h"

NS_ASSUME_NONNULL_BEGIN

#define KPigramLocalUserId @"KPigramLocalUserId"


NSString *const ReportedApplicationStateDidChangeNotification = @"ReportedApplicationStateDidChangeNotification";

@interface MainAppContext ()

@property (nonatomic, nullable) NSMutableArray<AppActiveBlock> *appActiveBlocks;

// POST GRDB TODO: Remove this
@property (nonatomic) NSUUID *disposableDatabaseUUID;

@end

#pragma mark -

@implementation MainAppContext

@synthesize mainWindow = _mainWindow;
@synthesize appLaunchTime = _appLaunchTime;
@synthesize buildTime = _buildTime;
@synthesize reportedApplicationState = _reportedApplicationState;

- (instancetype)init
{
    self = [super init];

    if (!self) {
        return self;
    }

    self.reportedApplicationState = UIApplicationStateInactive;

    _appLaunchTime = [NSDate new];
    _disposableDatabaseUUID = [NSUUID UUID];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];

    // We can't use OWSSingletonAssert() since it uses the app context.

    self.appActiveBlocks = [NSMutableArray new];
    
    return self;
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (UIApplicationState)reportedApplicationState
{
    @synchronized(self) {
        return _reportedApplicationState;
    }
}

- (void)setReportedApplicationState:(UIApplicationState)reportedApplicationState
{
    OWSAssertIsOnMainThread();

    @synchronized(self) {
        if (_reportedApplicationState == reportedApplicationState) {
            return;
        }
        _reportedApplicationState = reportedApplicationState;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ReportedApplicationStateDidChangeNotification
                                                        object:nil
                                                      userInfo:nil];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    self.reportedApplicationState = UIApplicationStateInactive;

    OWSLogInfo(@"");

    [NSNotificationCenter.defaultCenter postNotificationName:OWSApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    self.reportedApplicationState = UIApplicationStateBackground;

    OWSLogInfo(@"");
    [DDLog flushLog];

    [NSNotificationCenter.defaultCenter postNotificationName:OWSApplicationDidEnterBackgroundNotification object:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    self.reportedApplicationState = UIApplicationStateInactive;

    OWSLogInfo(@"");
    [DDLog flushLog];

    [NSNotificationCenter.defaultCenter postNotificationName:OWSApplicationWillResignActiveNotification object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    self.reportedApplicationState = UIApplicationStateActive;

    OWSLogInfo(@"");

    [NSNotificationCenter.defaultCenter postNotificationName:OWSApplicationDidBecomeActiveNotification object:nil];

    [self runAppActiveBlocks];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    OWSLogInfo(@"");
    [DDLog flushLog];
}

- (void)saveLocalUserIdToUserDefaults:(NSString *)userId {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:userId forKey:KPigramLocalUserId];

}

- (void)deleteLocalUserIdFromUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:KPigramLocalUserId];
}

+ (NSString *)localUserId {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [defaults objectForKey:KPigramLocalUserId];
}

#pragma mark -

- (BOOL)isMainApp
{
    return YES;
}

- (BOOL)isMainAppAndActive
{
    return [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
}

- (BOOL)isRTL
{
    static BOOL isRTL = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isRTL = [[UIApplication sharedApplication] userInterfaceLayoutDirection]
            == UIUserInterfaceLayoutDirectionRightToLeft;
    });
    return isRTL;
}

- (void)setStatusBarHidden:(BOOL)isHidden animated:(BOOL)isAnimated
{
    [[UIApplication sharedApplication] setStatusBarHidden:isHidden animated:isAnimated];
}

- (CGFloat)statusBarHeight
{
    return [UIApplication sharedApplication].statusBarFrame.size.height;
}

- (BOOL)isInBackground
{
    return self.reportedApplicationState == UIApplicationStateBackground;
}

- (BOOL)isAppForegroundAndActive
{
    return self.reportedApplicationState == UIApplicationStateActive;
}

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:
    (BackgroundTaskExpirationHandler)expirationHandler
{
    return [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:expirationHandler];
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier
{
    [UIApplication.sharedApplication endBackgroundTask:backgroundTaskIdentifier];
}

- (void)ensureSleepBlocking:(BOOL)shouldBeBlocking blockingObjects:(NSArray<id> *)blockingObjects
{
    if (UIApplication.sharedApplication.isIdleTimerDisabled != shouldBeBlocking) {
        if (shouldBeBlocking) {
            NSMutableString *logString =
                [NSMutableString stringWithFormat:@"Blocking sleep because of: %@", blockingObjects.firstObject];
            if (blockingObjects.count > 1) {
                [logString appendString:[NSString stringWithFormat:@"(and %lu others)", blockingObjects.count - 1]];
            }
            OWSLogInfo(@"%@", logString);
        } else {
            OWSLogInfo(@"Unblocking Sleep.");
        }
    }
    UIApplication.sharedApplication.idleTimerDisabled = shouldBeBlocking;
}

- (void)setMainAppBadgeNumber:(NSInteger)value
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:value];
}

- (nullable UIViewController *)frontmostViewController
{
    return UIApplication.sharedApplication.frontmostViewControllerIgnoringAlerts;
}

- (nullable UIAlertAction *)openSystemSettingsActionWithCompletion:(void (^_Nullable)(void))completion
{
    return [UIAlertAction actionWithTitle:CommonStrings.openSettingsButton
                  accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"system_settings")
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *_Nonnull action) {
                                      [UIApplication.sharedApplication openSystemSettings];
                                      if (completion != nil) {
                                          completion();
                                      }
                                  }];
}

- (BOOL)isRunningTests
{
    return getenv("runningTests_dontStartApp");
}

- (NSDate *)buildTime
{
    if (!_buildTime) {
        NSInteger buildTimestamp =
        [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"BuildDetails"][@"Timestamp"] integerValue];

        if (buildTimestamp == 0) {
#if RELEASE
            // Production builds should _always_ expire, ensure that here.
//            OWSFail(@"No build timestamp, assuming app never expires.");
#else
            OWSLogDebug(@"No build timestamp, assuming app never expires.");
#endif
            _buildTime = [NSDate distantFuture];
        } else {
            _buildTime = [NSDate dateWithTimeIntervalSince1970:buildTimestamp];
        }
    }

    return _buildTime;
}

- (UIInterfaceOrientation)interfaceOrientation
{
    return [UIApplication sharedApplication].statusBarOrientation;
}

- (void)setNetworkActivityIndicatorVisible:(BOOL)value
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:value];
}

#pragma mark -

- (void)runNowOrWhenMainAppIsActive:(AppActiveBlock)block
{
    OWSAssertDebug(block);

    DispatchMainThreadSafe(^{
        if (self.isMainAppAndActive) {
            // App active blocks typically will be used to safely access the
            // shared data container, so use a background task to protect this
            // work.
            OWSBackgroundTask *_Nullable backgroundTask =
                [OWSBackgroundTask backgroundTaskWithLabelStr:__PRETTY_FUNCTION__];
            block();
            OWSAssertDebug(backgroundTask);
            backgroundTask = nil;
            return;
        }

        [self.appActiveBlocks addObject:block];
    });
}

- (void)runAppActiveBlocks
{
    OWSAssertIsOnMainThread();
    OWSAssertDebug(self.isMainAppAndActive);

    // App active blocks typically will be used to safely access the
    // shared data container, so use a background task to protect this
    // work.
    OWSBackgroundTask *_Nullable backgroundTask = [OWSBackgroundTask backgroundTaskWithLabelStr:__PRETTY_FUNCTION__];

    NSArray<AppActiveBlock> *appActiveBlocks = [self.appActiveBlocks copy];
    [self.appActiveBlocks removeAllObjects];
    for (AppActiveBlock block in appActiveBlocks) {
        block();
    }

    OWSAssertDebug(backgroundTask);
    backgroundTask = nil;
}

- (id<SSKKeychainStorage>)keychainStorage
{
    return [SSKDefaultKeychainStorage shared];
}

- (NSString *)appDocumentDirectoryPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentDirectoryURL =
        [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [documentDirectoryURL path];
}
//hansen  share data
- (NSString *)appSharedDataDirectoryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    
    NSString *preferences = [[paths firstObject] stringByAppendingPathComponent:@"Pigram"];
       
    return preferences;

}

- (NSString *)appDatabaseBaseDirectoryPath
{
    if (SDSDatabaseStorage.shouldUseDisposableGrdb) {
        return [self.appSharedDataDirectoryPath stringByAppendingPathComponent:self.disposableDatabaseUUID.UUIDString];
    } else {
        return self.appSharedDataDirectoryPath;
    }
}

- (NSUserDefaults *)appUserDefaults
{
    return [[NSUserDefaults alloc] initWithSuiteName:SignalApplicationGroup];
}

@end

NS_ASSUME_NONNULL_END
