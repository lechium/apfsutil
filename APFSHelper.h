#import <Foundation/Foundation.h>

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);

@interface NSString (APFS)
- (NSDictionary *)deviceDictionaryFromRegex:(NSString *)pattern;
@end

@interface APFSHelper: NSObject
+ (NSArray *)returnForProcess:(NSString *)call;
+ (NSDictionary *)mountedDevices;
+ (NSArray *)deviceArray;
@end
