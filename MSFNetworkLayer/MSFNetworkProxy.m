//
//  MSFNetworkProxy.m
//  MSFNetworkLayer
//
//  Created by Fanta Xu on 16/5/10.
//  Copyright © 2016年 Fanta Xu. All rights reserved.
//

#import "MSFNetworkProxy.h"
#import <MsfSDK/MsfSDK.h>

#define KMSFAnswerFlag_NeedAnswer  0x1 // 需要server应答的包

void GetInt32Ptr(int *to, unsigned char * from)
{
    *(unsigned char*)(to) = *(from + 3);
    *((unsigned char*)(to)+1) = *(from+2);
    *((unsigned char*)(to)+2) = *(from + 1);
    *((unsigned char*)(to)+3) = *from;
}

@implementation MSFNetworkProxy
{
    MsfSDK *_msfSDK;
}

- (int)preSendWupBuffer
{
    return [_msfSDK getNextSendPacketSeqId];
}

- (BOOL)sendWupBuffer:(unsigned char *)pWup cmd:(NSString *)cmd resendSeq:(int)iResendReq seq:(int *)pSeq immediately:(BOOL)bImmediately timeOut:(int)iInterval
{
    int wupLen = 0;
    GetInt32Ptr(&wupLen, (unsigned char*)pWup);
    if (0 > wupLen || 100000 < wupLen) {
        return -1;
    }
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithFormat:@"%d", EMSFSendPacketType_Normal], @"type",
                                 @"3031376627", @"uin",
                                 cmd, @"cmd",
                                 [NSData dataWithBytes:pWup length:wupLen], @"data",
                                 
                                 [NSString stringWithFormat:@"%d", iInterval], @"timeout",
                                 
                                 [NSString stringWithFormat:@"%d", bImmediately ? 1 : 0], @"sendPriority",
                                 [NSString stringWithFormat:@"%d", (int)KMSFAnswerFlag_NeedAnswer], @"answerFlag",
                                 [NSString stringWithFormat:@"%d", 0], @"resendNum",
                                 [NSString stringWithFormat:@"%d", 0], @"isNotResend",
                                 nil];
    
    if(iResendReq > 0)
    {
        [dict setObject:[NSString stringWithFormat:@"%d", iResendReq] forKey:@"seqId"];
    }
    int retSeq = [_msfSDK sendPacket:dict];
    
    if(pSeq) *pSeq = retSeq;
    
    return 0;
}

- (int)cancelMSFPacket:(int)seq
{
    [_msfSDK cancelPacket:seq];
    return 0;
}

@end
