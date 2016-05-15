//
//  GSCache.m
//  QQMSFContact
//
//  Created by Fanta Xu on 15/11/26.
//
//

#import "GSCache.h"
#import "GSCacheObject.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@interface GSCache ()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation GSCache

+ (instancetype)sharedInstance
{
    static GSCache *staticInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticInstance = [GSCache new];
    });
    return staticInstance;
}

- (NSCache *)cache
{
    if (_cache == nil) {
        _cache = [[NSCache alloc] init];
        _cache.countLimit = 1000;
    }
    return _cache;
}

- (NSDictionary *)fetchDataWithServiceID:(NSString *)serviceID serviceType:(int)serviceType requestIdentifier:(NSString *)requestIdentifier
{
    NSString *key = [self keyWithServiceID:serviceID serviceType:serviceType requestIdentifier:requestIdentifier];
    GSCacheObject *cacheObj = [self.cache objectForKey:key];
    if (cacheObj.isOutdated || cacheObj.isEmpty) {
        return nil;
    }
    else {
        return cacheObj.content;
    }
}

- (void)saveCacheWithData:(NSDictionary *)cacheData cacheTime:(NSInteger)cacheTime serviceID:(NSString *)serviceID serviceType:(int)serviceType requestIdentifier:(NSString *)requestIdentifier
{
    NSString *key = [self keyWithServiceID:serviceID serviceType:serviceType requestIdentifier:requestIdentifier];
    GSCacheObject *cacheObj = [self.cache objectForKey:key];
    if (cacheObj) {
        [cacheObj updateContent:cacheData];
    }
    else {
        cacheObj = [[GSCacheObject alloc] initWithContent:cacheData cacheTime:cacheTime];
        [self.cache setObject:cacheObj forKey:key];
    }
}

- (void)deleteCacheWithServiceID:(NSString *)serviceID serviceType:(int)serviceType requestIdentifier:(NSString *)requestIdentifier
{
    NSString *key = [self keyWithServiceID:serviceID serviceType:serviceType requestIdentifier:requestIdentifier];
    [self.cache removeObjectForKey:key];
}

- (void)clean
{
    [self.cache removeAllObjects];
}

- (NSString *)keyWithServiceID:(NSString *)serviceID serviceType:(int)serviceType requestIdentifier:(NSString *)requestIdentifier
{
    return [NSString stringWithFormat:@"%@-%d-%@", serviceID, serviceType, requestIdentifier];
}

@end
