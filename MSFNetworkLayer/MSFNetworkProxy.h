//
//  MSFNetworkProxy.h
//  MSFNetworkLayer
//
//  Created by Fanta Xu on 16/5/10.
//  Copyright © 2016年 Fanta Xu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSFNetworkProxy : NSObject

- (int)preSendWupBuffer;

- (BOOL)sendWupBuffer:(unsigned char *)pWup cmd:(NSString *)cmd resendSeq:(int)iResendReq seq:(int *)pSeq immediately:(BOOL)bImmediately timeOut:(int)iInterval;
- (int)cancelMSFPacket:(int)seq;

@end
