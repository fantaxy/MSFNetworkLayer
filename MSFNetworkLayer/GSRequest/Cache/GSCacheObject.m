//
//  GSCacheObject.m
//  QQMSFContact
//
//  Created by Fanta Xu on 15/11/26.
//
//

#import "GSCacheObject.h"

#if !__has_feature(objc_arc)
#error  does not support Objective-C Automatic Reference Counting (ARC)
#endif

@interface GSCacheObject ()

@property (nonatomic, copy, readwrite) NSDictionary *content;
@property (nonatomic, copy, readwrite) NSDate *lastUpdateTime;

@end

@implementation GSCacheObject

#pragma mark - getters and setters
- (BOOL)isEmpty
{
    return self.content == nil;
}

- (BOOL)isOutdated
{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.lastUpdateTime];
    return timeInterval > self.cacheTimeInSeconds;
}

- (void)setContent:(NSData *)content
{
    _content = [content copy];
    self.lastUpdateTime = [NSDate dateWithTimeIntervalSinceNow:0];
}

#pragma mark - life cycle
- (instancetype)initWithContent:(NSDictionary *)content cacheTime:(NSInteger)cacheTime
{
    self = [super init];
    if (self) {
        _cacheTimeInSeconds = cacheTime;
        [self setContent:content];
    }
    return self;
}

#pragma mark - public method
- (void)updateContent:(NSDictionary *)content
{
    [self setContent:content];
}

@end
