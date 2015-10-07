#import <Foundation/NSDistributedNotificationCenter.h>

@interface BBServer : NSObject
-(void)_loadSavedSectionInfo;
@end

// #define DEBUG
#ifdef DEBUG
	#define TweakLog(fmt, ...) NSLog((@"[NotificationProfiles] [Line %d]: "  fmt), __LINE__, ##__VA_ARGS__)
#else
	#define TweakLog(fmt, ...)
	#define NSLog(fmt, ...)
#endif

static BBServer *_BBServer = nil;

%hook BBServer
- (id)init
{
	_BBServer = %orig;
	return _BBServer;
}
%end

%ctor
{
	@autoreleasepool {
		%init;

		[[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"net.tateu.notificationprofiles/loadSectionInfo" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
			TweakLog(@"loadSectionInfo - %@", _BBServer);
			if (_BBServer) {
				[_BBServer _loadSavedSectionInfo];
			}
		}];
	}
}
