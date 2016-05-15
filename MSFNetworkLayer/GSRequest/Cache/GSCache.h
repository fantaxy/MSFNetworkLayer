//
//  GSCache.h
//  QQMSFContact
//
//  Created by Fanta Xu on 15/11/26.
//
//

#import <Foundation/Foundation.h>

@interface GSCache : NSObject

+ (instancetype)sharedInstance;

- (NSDictionary *)fetchDataWithServiceID:(NSString *)serviceID
                             serviceType:(int)serviceType
                       requestIdentifier:(NSString *)requestIdentifier;

- (void)saveCacheWithData:(NSDictionary *)cacheData
                cacheTime:(NSInteger)cacheTime
                serviceID:(NSString *)serviceID
              serviceType:(int)serviceType
        requestIdentifier:(NSString *)requestIdentifier;

- (void)deleteCacheWithServiceID:(NSString *)serviceID
                     serviceType:(int)serviceType
               requestIdentifier:(NSString *)requestIdentifier;

- (void)clean;

@end
