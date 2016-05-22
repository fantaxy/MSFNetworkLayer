//
//  MSFNetworkProxy.m
//  MSFNetworkLayer
//
//  Created by Fanta Xu on 16/5/10.
//  Copyright © 2016年 Fanta Xu. All rights reserved.
//

#import "MSFNetworkProxy.h"
#import <MsfSDK/MsfSDK.h>

#define IMSERVICE_ID  537046030
#define KMSFAnswerFlag_NeedAnswer  0x1 // 需要server应答的包
#define KUsingUin @"3031376627"

void GetInt32Ptr(int *to, unsigned char * from)
{
    *(unsigned char*)(to) = *(from + 3);
    *((unsigned char*)(to)+1) = *(from+2);
    *((unsigned char*)(to)+2) = *(from + 1);
    *((unsigned char*)(to)+3) = *from;
}

@interface MSFNetworkProxy () <MsfSDKCallbackProtocol>

@end

@implementation MSFNetworkProxy
{
    MsfSDK *_msfSDK;
}

+ (instancetype)getInstance
{
    static MSFNetworkProxy *staticInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticInstance = [[self alloc] init];
    });
    return staticInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _msfSDK = [[MsfSDK alloc] initWithAppId:IMSERVICE_ID andCallback:self];
    }
    return self;
}

- (NSNumber *)preSendWupBuffer
{
    int seq = [_msfSDK getNextSendPacketSeqId];
    return @(seq);
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
                                 KUsingUin, @"uin",
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
        [dict setObject:@(iResendReq) forKey:@"seqId"];
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

#pragma mark - MSF Callback

- (void)onMSFIllegalApp:(NSDictionary*)aDict
{
    FATLog(@"Illegal app, %d", IMSERVICE_ID);
}

- (void)onMSFNotGrayUser:(NSDictionary*)aDict
{
    FATLog(@"Illegal gray user,appid: %d", IMSERVICE_ID);
}

- (void)onMSFNetworkState:(NSDictionary*)aDict
{
    NSString* state = aDict[@"state"];
    NSString* addr = aDict[@"ssoip"];
    NSString* port = aDict[@"ssoport"];
    NSString* isAppInvoke = aDict[@"isAppInvoke"];
    
    if([state intValue] == EMSFNetwork_ConnectSuccess)
    {
        FATLog(@"SSO IP:%@ Port:%@ isAppInvoke:%@", addr,port,isAppInvoke);
    }
}

- (void)onMSFApnState:(NSDictionary*)aDict
{
    FATLog(@"%@", aDict);
}

- (void)onMSFPacketState:(NSDictionary*)aDict
{
    int state = [aDict[@"state"] intValue];
    NSString *cmd = aDict[@"cmd"];
    NSData *data = aDict[@"recvData"];
    NSNumber *seqId = aDict[@"seqId"];
    
    if(state == EMSFPacket_Success && [data length] > 0) {
        
        if([cmd length] == 0 || !seqId || [data length] < 4) {
            return;
        }
        
        [_msfDelegate OnMSFPacketState:aDict];
        [_msfDelegate OnMSFRecvDataFromBackend:cmd buf:data seq:seqId];
    }
    else {
        // 注意：该分支有3种情况：
        // 1 需要回包，没收到回包，状态是失败
        // 2 需要回包，并收到回包，状态是成功，但后台回包数据为空的情况
        // 3 不需要回包，然后发成功即通知的情况，状态是成功
        
        NSMutableDictionary * newDict = [NSMutableDictionary dictionaryWithDictionary:aDict];
        NSString * errTips = newDict[@"errTips"];
        if([errTips length] == 0) {
            NSString * errorMsg = @"网络错误";
            newDict[@"errTips"] = errorMsg;
        }
        
        [_msfDelegate OnMSFPacketState:newDict];
    }
}

- (void)onMSFSocketFlow:(NSArray*)aDict
{
    FATLog(@"%@", aDict);
}

- (void)onMSFSSOReturn:(NSDictionary*)aDict
{
    FATLog(@"A2 Error: %@", aDict);
}

- (void)onMSFNetworkSocketHandle:(NSDictionary*)aDict
{
    FATLog(@"%@", aDict);
}

-(void)onHTTPStatus:(NSDictionary*)aDict;
{
    FATLog(@"%@", aDict);
}

- (void)onMSFServerTimeUpdated:(NSDictionary*)aDict
{
    FATLog(@"%@", aDict);
    long long aPacketTimeCost = [aDict[@"packetTimeCost"] longLongValue];
    if(aPacketTimeCost < 7000) {//收发包时间过长则忽略，保证精度
        [_msfDelegate onMSFServerTimeUpdated:aDict];
    }
}

@end
