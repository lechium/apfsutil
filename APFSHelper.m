#import "APFSHelper.h"
#include <sys/stat.h>
#import "iokit.h"

@implementation NSString (APFS)
- (NSDictionary *)deviceDictionaryFromRegex:(NSString *)pattern  {
    NSMutableDictionary *devices = [NSMutableDictionary new];
    NSError *error = NULL;
    NSRange range = NSMakeRange(0, self.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
    NSArray *matches = [regex matchesInString:self options:NSMatchingReportProgress range:range];
    for (NSTextCheckingResult *entry in matches) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        //NSMutableArray *itemArray = [NSMutableArray new];
        for (NSInteger i = 1; i < entry.numberOfRanges; i++) {
            NSRange range = [entry rangeAtIndex:i];
            if (range.location != NSNotFound){
                NSString *text = [self substringWithRange:range];
                switch (i) {
                    case 1:
                        dict[@"BSDName"] = text;
                        break;
                    case 2:
                        dict[@"Path"] = text;
                        break;
                    case 3:
                        dict[@"Type"] = text;
                        break;
                }
                //[itemArray addObject:text];
            }
        }
        devices[dict[@"BSDName"]] = dict;
        //[array addObject:dict];
    }
   return devices;
}

@end

@implementation APFSHelper

+ (NSArray *)returnForProcess:(NSString *)call {
    if (call==nil)
        return 0;
    char line[200];
    //DLog(@"\nRunning process: %@\n", call);
    FILE* fp = popen([call UTF8String], "r");
    NSMutableArray *lines = [[NSMutableArray alloc]init];
    if (fp) {
        while (fgets(line, sizeof line, fp)){
            NSString *s = [NSString stringWithCString:line encoding:NSUTF8StringEncoding];
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [lines addObject:s];
        }
    }
    pclose(fp);
    return lines;
}

+ (NSString *)mountDetails {
    return [[self returnForProcess:@"/sbin/mount"]componentsJoinedByString:@"\n"];
}

+ (NSDictionary *)mountedDevices {
    NSString *mount = [self mountDetails];
    //NSLog(@"mount: %@", mount);
    return [mount deviceDictionaryFromRegex:@"([@./\\w-]*)\\son\\s([./\\w]*)\\s\\(([\\w]*)"]; //([@./\w-]*)\son\s([./\w]*)\s\(([\w]*)
}

+ (NSArray *)deviceArray {
    NSMutableArray *deviceArray = [NSMutableArray new];
    NSDictionary *mountedDevices = [self mountedDevices];
    //DLog(@"mountedDevices: %@", mountedDevices);
    mach_port_t masterPort = 0;
    IOMasterPort(MACH_PORT_NULL, &masterPort);
    CFMutableDictionaryRef classesToMatch = IOServiceMatching("AppleAPFSVolume");
    io_iterator_t matchingServices;
    kern_return_t kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, &matchingServices);
    if (kernResult != KERN_SUCCESS) {
        DLog(@"failed to find AppleAPFSVolume services");
        return nil;
    }
    io_service_t svc = 0;
    CFMutableDictionaryRef properties = 0;
    io_string_t path;
    while ((svc = IOIteratorNext(matchingServices))) {
        assert(KERN_SUCCESS == IORegistryEntryCreateCFProperties(svc, &properties, 0, 0));
        NSDictionary* propd = ((__bridge NSDictionary*)properties);
        NSNumber *roleValue = propd[@"RoleValue"];
        NSString *fullName = propd[@"FullName"];
        NSNumber *bsdUnitNumber = propd[@"BSD Unit"];
        NSString *bsdName = propd[@"BSD Name"];
        NSNumber *size = propd[@"Size"];
        NSNumber *open = propd[@"Open"];
        NSString *bsdPath = [@"/dev" stringByAppendingPathComponent:bsdName];
        NSDictionary *mounted = mountedDevices[bsdPath];
        NSString *mountedPath = mounted[@"Path"];
        IORegistryEntryGetPath(svc, kIOServicePlane, path);
        //LOG("%s", path);
        NSString *pathString = [NSString stringWithUTF8String:path];
        NSString *pathName = [pathString lastPathComponent];
        NSArray *pathComponents = [pathName componentsSeparatedByString:@"@"];
        NSString *lpc = [pathComponents lastObject];
        if (!fullName) {
            fullName = [pathComponents firstObject];
        }
        NSMutableDictionary *newProps = [NSMutableDictionary new];
        int i = [lpc intValue];
        newProps[@"BSD Name"] = bsdName;
        newProps[@"BSD Path"] = bsdPath;
        newProps[@"FullName"] = fullName;
        newProps[@"RoleValue"] = roleValue;
        newProps[@"Path"] = pathString;
        newProps[@"BSDUnit"] = bsdUnitNumber;
        newProps[@"BSD Partition"] = @(i);
        newProps[@"Size"] = size;
        newProps[@"Open"] = open;
        if (mountedPath){
            newProps[@"MountPath"] = mountedPath;
        }
        [deviceArray addObject:newProps];
    }
    IOObjectRelease(svc);
    IOObjectRelease(matchingServices);
    mach_port_deallocate(mach_task_self(), masterPort);
    return deviceArray;
}

@end
