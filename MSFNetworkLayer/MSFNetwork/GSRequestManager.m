//
//  GSRequestManager.m
//  MSFNetworkLayer
//
//  Created by Fanta Xu on 16/5/15.
//  Copyright © 2016年 Fanta Xu. All rights reserved.
//

#import "GSRequestManager.h"
#import "MSFNetworkProxy.h"

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
    
}

- (void)OnMSFRecvDataFromBackend:(const char*)aCmd buf:(unsigned char*)aBuf bufLen:(int)aBufLen seq:(int)aSeq
{
    
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
