#import "APFSHelper.h"


@implementation NSString (APFS)
- (NSArray *)matchesWithRegex:(NSString *)pattern  {
    NSMutableArray *array = [NSMutableArray new];
    NSError *error = NULL;
    NSRange range = NSMakeRange(0, self.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
    NSArray *matches = [regex matchesInString:self options:NSMatchingReportProgress range:range];
    for (NSTextCheckingResult *entry in matches) {
        for (NSInteger i = 0; i < entry.numberOfRanges; i++) {
            NSRange range = [entry rangeAtIndex:i];
            if (range.location != NSNotFound){
                NSString *text = [self substringWithRange:range];
                [array addObject:text];
            }
        }
    }
    return array;
}
@end

@implementation APFSHelper


@end
