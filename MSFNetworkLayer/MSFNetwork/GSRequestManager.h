//
//  GSRequestManager.h
//  MSFNetworkLayer
//
//  Created by Fanta Xu on 16/5/15.
//  Copyright © 2016年 Fanta Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMSFDelegate.h"
#import "GSBaseRequest.h"

#define NOTIFYERROR_KEY_ERRORCODE @"errorCode"
#define NOTIFYERROR_KEY_ERRTIPS @"errTips"

@interface GSRequestManager : NSObject<IMSFDelegate>

+ (instancetype)getInstance;

- (NSNumber *)sendRequest:(GSBaseRequest *)request success:(GSRequestCallBack)success fail:(GSRequestCallBack)fail;

- (void)cancelRequest:(NSNumber *)seq;

@end
