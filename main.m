#include <stdio.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <libgen.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <mach-o/loader.h>
#include <sys/utsname.h>
#import "libjb.h"
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>
#import <sys/utsname.h>

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);

#define OPTION_FLAGS "d:lrhp"

char *progname;
char *path;

static struct option longopts[] = {
    { "list",                      no_argument,            NULL,   'l' },
    { "delete",                    required_argument,      NULL,   'd' },
    { "help",                      no_argument,            NULL,   'h' },
    { "refresh",                   no_argument,            NULL,   'r' },
    { "prefix",                    no_argument,            NULL,   'p' },
    { NULL,                        0,                      NULL,    0  }
};

void cmd_help(void){
    printf("Usage: APFSUtil [OPTIONS] Volume\n");
    printf("List & delete apfs volumes and refresh the prefix conf file\n\n");
    
    printf("  -h, --help\t\tprints usage information\n");
    printf("  -d, --delete\t\tthe volume to delete\n");
    printf("  -l, --list\t\tlists all the APFS volumes on the device\n");
    printf("  -r, --refresh\t\trefresh the prefix conf file\n");
    printf("  -p, --prefix\t\tprint out the current prefix\n");
    printf("\n");
}

int main(int argc, char **argv) {
    @autoreleasepool {
        progname = basename(argv[0]);
        path = dirname(argv[0]);
        int flag;
        NSString *volume = nil;
        while ((flag = getopt_long(argc, argv, OPTION_FLAGS, longopts, NULL)) != -1) {
            switch(flag) {
                case 'h':
                    cmd_help();
                    return 0;
                case 'l':
                    DLog(@"%@", [JBManager deviceArray]);
                    return 0;
                case 'd':
                    volume = [NSString stringWithUTF8String:optarg];
                    return [JBManager deleteVolume:volume];
                case 'r':
                    return [JBManager refreshPrefix];
                case 'p':
                    DLog(@"%@", [JBManager jbPrefix]);
                    return 0;
                default:
                    cmd_help();
                    return -1;
            }
        }
        cmd_help();
    }
    return 0;
}

