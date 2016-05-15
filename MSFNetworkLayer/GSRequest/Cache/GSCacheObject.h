//
//  GSCacheObject.h
//  QQMSFContact
//
//  Created by Fanta Xu on 15/11/26.
//
//

#import <Foundation/Foundation.h>

@interface GSCacheObject : NSObject

@property (nonatomic, copy, readonly) NSDictionary *content;
@property (nonatomic, copy, readonly) NSDate *lastUpdateTime;
@property (nonatomic, assign, readonly) NSInteger cacheTimeInSeconds;

@property (nonatomic, assign, readonly) BOOL isOutdated;
@property (nonatomic, assign, readonly) BOOL isEmpty;

- (instancetype)initWithContent:(NSDictionary *)content cacheTime:(NSInteger)cacheTime;
- (void)updateContent:(NSDictionary *)content;

@end
