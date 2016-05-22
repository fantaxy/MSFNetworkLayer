//
//  GSRequestManager.m
//  MSFNetworkLayer
//
//  Created by Fanta Xu on 16/5/15.
//  Copyright © 2016年 Fanta Xu. All rights reserved.
//

#import "GSRequestManager.h"
#import "MSFNetworkProxy.h"

#import <MsfSDK/MsfSDK.h>

@interface GSRequestOperation : NSObject

@property (nonatomic, strong) GSBaseRequest *request;
@property (nonatomic, copy) GSRequestCallBack successBlock;
@property (nonatomic, copy) GSRequestCallBack failBlock;

@end

@implementation GSRequestOperation

- (instancetype)initWithRequest:(GSBaseRequest *)request success:(GSRequestCallBack)success fail:(GSRequestCallBack)fail
{
    if (self = [super init]) {
        _request = request;
        _successBlock = [success copy];
        _failBlock = [fail copy];
    }
    return self;
}

@end

@interface GSRequestManager ()

@property (nonatomic, strong) NSMutableDictionary *dispatchTable;

@end

@implementation GSRequestManager

+ (instancetype)getInstance
{
    static GSRequestManager *staticInstacne = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticInstacne = [[self alloc] init];
    });
    return staticInstacne;
}

- (NSNumber *)sendRequest:(GSBaseRequest *)request success:(GSRequestCallBack)success fail:(GSRequestCallBack)fail
{
    NSNumber *seq = [[MSFNetworkProxy getInstance] preSendWupBuffer];
    GSRequestOperation *wrapRequest = [[GSRequestOperation alloc] initWithRequest:request success:success fail:fail];
    self.dispatchTable[seq] = wrapRequest;
    
    [[MSFNetworkProxy getInstance] sendWupBuffer:[request getRequestBuffer] cmd:request.serviceCmd resendSeq:[seq intValue] seq:nil immediately:YES timeOut:15];
    return seq;
}

- (void)cancelRequest:(NSNumber *)seq
{
    [[MSFNetworkProxy getInstance] cancelMSFPacket:[seq intValue]];
}


#pragma mark - MSF Call back

- (void)OnMSFPacketState:(NSDictionary*)aDict
{
    NSString *strServiceCmd = aDict[@"cmd"];
    NSNumber *seqId = aDict[@"seqId"];
    int iState = [aDict[@"state"] intValue];
//    int iFailReason = [aDict[@"failReason"] intValue];
    GSRequestOperation *wrapRequest = self.dispatchTable[seqId];
    GSBaseRequest *request = wrapRequest.request;
    if (request) {
        if (iState == EMSFPacket_Fail) {
            NSString * errTips = aDict[@"errTips" ];
            FATLog(@"Request %@ failed for reason: %@", strServiceCmd, errTips);
            request.errorMessage = errTips;
            wrapRequest.failBlock(request, nil);
            self.dispatchTable[seqId] = nil;
        }
        else if(iState == EMSFPacket_Success && request) {
            self.dispatchTable[seqId] = nil;
        }
        else {
            wrapRequest.failBlock(request, nil);
        }
    }
}

- (void)OnMSFRecvDataFromBackend:(NSString *)aCmd buf:(NSData *)aData seq:(NSNumber *)aSeq
{
    GSRequestOperation *wrapRequest = self.dispatchTable[aSeq];
    GSBaseRequest *request = wrapRequest.request;
    NSDictionary *userInfo = [request notifyRespBuffer:[aData bytes] len:(int)aData.length seq:[aSeq intValue]];
    wrapRequest.successBlock(request, userInfo);
    self.dispatchTable[aSeq] = nil;
}

- (void)OnMSFSSOErrorStateResult:(NSDictionary*)aDict
{
    
}

- (void)OnMSFNetworkState:(NSDictionary*)aDict
{
    
}

- (void)OnMSFApnState:(NSDictionary*)aDict
{
    
}


- (void)OnMSFSocketFlow:(NSArray*)aDictArray
{
    
}

- (void)OnMSFIllegalGrayApp:(NSDictionary*)aDict
{
    
}

- (void)OnMSFMsg:(NSDictionary*)aDict
{
    
}

- (void)onMSFServerTimeUpdated:(NSDictionary*)aDict
{
    
}

- (void)onHTTPStatus:(NSDictionary*)aDict
{
    
}

#pragma mark - Getter/Setter

- (NSMutableDictionary *)dispatchTable
{
    if (_dispatchTable == nil) {
        _dispatchTable = [[NSMutableDictionary alloc] init];
    }
    return _dispatchTable;
}

@end
