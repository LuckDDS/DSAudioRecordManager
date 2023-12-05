//
//  DSCommonTool.m
//  DSAudioRecord
//
//  Created by DDS on 2023/12/4.
//

#import "DSCommonTool.h"

@implementation DSCommonTool
+ (NSInteger)getCurrentTime {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSString *timeStamp = [NSString stringWithFormat:@"%lld", (long long)interval];
    return [timeStamp integerValue];
}
@end
