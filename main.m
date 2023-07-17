#include <stdio.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <sys/stat.h>
#import "iokit.h"
#import "NSTask.h"

#include <sys/stat.h>
#include <sys/param.h>
#include <mach-o/loader.h>
#include <sys/utsname.h>

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);

int APFSVolumeDelete(const char *path);
//49874 == volume busy?
//49154 == volume doesnt exist?
//49890 == missing entitlements

BOOL queryUserWithString(NSString *query) {
    
    NSString *errorString = [NSString stringWithFormat:@"\n%@ [y/n]? ", query];
    char c;
    printf("%s", [errorString UTF8String] );
    c=getchar();
    while(c!='y' && c!='n') {
        if (c!='\n'){
            printf("[y/n]");
        }
        c=getchar();
    }
    if (c == 'n') {
        return FALSE;
    } else if (c == 'y') {
        return TRUE;
    }
    return FALSE;
}

NSArray * deviceArray() {
    NSMutableArray *deviceArray = [NSMutableArray new];
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
        IORegistryEntryGetPath(svc, kIOServicePlane, path);
        //LOG("%s", path);
        NSString *pathString = [NSString stringWithUTF8String:path];
        NSString *lpc = [[[pathString lastPathComponent] componentsSeparatedByString:@"@"] lastObject];
        NSMutableDictionary *newProps = [NSMutableDictionary new];
        int i = [lpc intValue];
        newProps[@"BSD Name"] = bsdName;
        newProps[@"FullName"] = fullName;
        newProps[@"RoleValue"] = roleValue;
        newProps[@"Path"] = pathString;
        newProps[@"BSDUnit"] = bsdUnitNumber;
        newProps[@"BSD Partition"] = @(i);
        newProps[@"Size"] = size;
        newProps[@"Open"] = open;
        [deviceArray addObject:newProps];
    }
    IOObjectRelease(svc);
    IOObjectRelease(matchingServices);
    mach_port_deallocate(mach_task_self(), masterPort);
    /*
    if (!checkra1n) {
        NSLog(@"[checkra1n:overlay_hook] checkra1n volume doesn't exist yet!");
        NSString *base = [root substringToIndex:root.length-2];
        checkra1n = [NSString stringWithFormat:@"/dev/%@s%lu", base,checkBlock];
        *check = [checkra1n UTF8String];
        run_command("/sbin/newfs_apfs","-e", "-v", "checkra1n", "-A", [[NSString stringWithFormat:@"/dev/%@", base] UTF8String], NULL);
    }*/
    return deviceArray;
}

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
        DLog(@"");
        if (argc < 2) {
            DLog(@"You must choose an APFS volume to delete, listing APFS volumes instead.");
            NSArray *da = deviceArray();
            DLog(@"%@", da);
        } else {
            char *path = argv[1];
            DLog(@"Attempting to delete volume: %s", path);
            if (queryUserWithString(@"Are you sure?")) {
                int deleteProgress = APFSVolumeDelete(path);
                DLog(@"\nVolume deleted with return status: %d", deleteProgress);
                if (deleteProgress == 49874 || deleteProgress == 49890) {
                    DLog(@"\nThe volume is currently busy, try unmounting first!\n\n");
                }
                return deleteProgress;
            } else {
                DLog(@"\nBailed\n\n");
            }
            
        }
	}
}
