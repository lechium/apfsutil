#include <stdio.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#include <sys/stat.h>
#include <sys/param.h>
#include <mach-o/loader.h>
#include <sys/utsname.h>
#import "APFSHelper.h"

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
        return false;
    } else if (c == 'y') {
        return true;
    }
    return false;
}

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
        DLog(@"");
        if (argc < 2) {
            DLog(@"You must choose an APFS volume to delete, listing APFS volumes instead.");
            NSArray *da = [APFSHelper deviceArray];
            DLog(@"%@", da);
        } else {
            char *path = argv[1];
            DLog(@"Attempting to delete volume: %s", path);
            if (queryUserWithString(@"Are you sure?")) {
                int deleteProgress = APFSVolumeDelete(path);
                DLog(@"\nVolume deleted with return status: %d", deleteProgress);
                if (deleteProgress == 49874) {
                    DLog(@"\nThe volume is currently busy, try unmounting first!\n\n");
                }
                return deleteProgress;
            } else {
                DLog(@"\nBailed\n\n");
            }
        }
    }
}
