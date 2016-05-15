//
//  GSBaseRequest.m
//  QQMSFContact
//
//  Created by Fanta Xu on 15/11/21.
//
//

#import "GSBaseRequest.h"
#import "GSRequestManager.h"
#import "AFNetworkReachabilityManager.h"
//#import "oidb_sso.pb.h"
//#import "PBProxy.h"
#import "GSCache.h"
#import "GSDebugLabel.h"
//#import "NSObject+Description.h"
#import "string.h"
#include "stdio.h"

#if !__has_feature(objc_arc)
#error  does not support Objective-C Automatic Reference Counting (ARC)
#endif

@interface GSBaseRequest ()

@property (nonatomic, weak) NSObject<GSRequestProtocol> *child;
@property (nonatomic, strong) GSCache *cache;
@property (nonatomic, strong) GSDebugLabel *debugLabel;

@end

@implementation GSBaseRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _delegate = nil;
        _errorMessage = nil;
        _errorType = GSRequestErrorTypeDefault;
        _openDebugMode = NO;
        
        [self initDebugLabel];
        
        if ([self conformsToProtocol:@protocol(GSRequestProtocol)]) {
            self.child = (id<GSRequestProtocol>)self;
        }
        else {
            assert(NO);
        }
    }
    return self;
}

- (void)dealloc
{
    [self.cache clean];
    [self cleanStatus];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)serviceCmd
{
	//传给MSF的命令字必须遵循OidbSvc.xxxx格式
    return [NSString stringWithFormat:@"OidbSvc.0x%x", [self.child serviceNumber]];
}

- (BOOL)isReachable
{
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

- (BOOL)shouldCallBackOnMainThread
{
    return YES;
}

#pragma mark - calling api

- (void)load
{
    [self doLoad:NO];
}

- (void)loadWithoutCache
{
    [self doLoad:YES];
}

- (void)loadWithCompletionBlockSuccess:(void (^)(GSBaseRequest *, NSDictionary *))success failure:(void (^)(GSBaseRequest *, NSDictionary *))failure
{
    [self setCompletionBlockSuccess:success failure:failure];
    [self load];
}

- (void)cancel
{
    [[GSRequestManager getInstance] cancelRequest:self.requestID];
    [self cleanStatus];
}

- (void)cleanStatus
{
    self.errorType = GSRequestErrorTypeDefault;
    self.errorMessage = nil;
    self.successBlock = nil;
    self.failBlock = nil;
}

#pragma mark - cache method

- (BOOL)shouldCache
{
    return NO;
}

- (NSInteger)cacheTimeInSeconds
{
    return 0;
}

- (NSString *)cacheKey
{
    return nil;
}

#pragma mark - private methods

- (void)doLoad:(BOOL)ignoreCache
{
    [self addAdditionalParameters];
    self.isLoading = YES;
    //检查缓存
    if (!ignoreCache && [self shouldCache]) {
        NSDictionary *cacheData = [self.cache fetchDataWithServiceID:[NSString stringWithFormat:@"%x",[self.child serviceNumber]]
                                                         serviceType:self.serviceType
                                                   requestIdentifier:self.cacheKey];
        if (cacheData) {
            self.errorType = GSRequestErrorTypeSuccess;
            if ([self shouldCallBackOnMainThread]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self callBackWithUserInfo:cacheData];
                });
            }
            else {
                [self callBackWithUserInfo:cacheData];
            }
            return;
        }
    }
    
    //检查网络
    if (![self isReachable]) {
        self.errorType = GSRequestErrorTypeNoNetWork;
        self.errorMessage = @"操作失败，请检查网络连接。";
        if ([self shouldCallBackOnMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callBackWithUserInfo:nil];
            });
        }
        else {
            [self callBackWithUserInfo:nil];
        }
        return;
    }
    
    [self doSendRequest];
}

- (void)setCompletionBlockSuccess:(void (^)(GSBaseRequest *, NSDictionary *))success failure:(void (^)(GSBaseRequest *, NSDictionary *))failure
{
    self.successBlock = success;
    self.failBlock = failure;
}

- (void)addAdditionalParameters
{
    return;
}

- (void)doSendRequest
{
    self.errorType = GSRequestErrorTypeDefault;
    [self beforePerformRequest];
    __weak GSBaseRequest *weakSelf = self;
    self. requestID = [[GSRequestManager getInstance] sendRequest:self success:^(GSBaseRequest *request, NSDictionary *userInfo) {
        //回包数据如果已经完成数据校验 才把状态设为成功
        if (weakSelf.errorType != GSRequestErrorTypeLogicError) {
            weakSelf.errorType = GSRequestErrorTypeSuccess;
        }
        [weakSelf callBackWithUserInfo:userInfo];
    } fail:^(GSBaseRequest *request, NSDictionary *userInfo) {
        weakSelf.errorType = GSRequestErrorTypeTimeout;
        weakSelf.errorMessage = userInfo[NOTIFYERROR_KEY_ERRTIPS];
        [weakSelf showDebugInfo:[NSString stringWithFormat:@"Request timeout: %@", weakSelf.errorMessage]];
        [weakSelf callBackWithUserInfo:userInfo];
    }];
    [self afterPerformRequest];
}

- (void)callBackWithUserInfo:(NSDictionary *)userInfo
{
    if ([self shouldCallBackOnMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performcallBackWithUserInfo:userInfo];
        });
    }
    else {
        [self performcallBackWithUserInfo:userInfo];
    }
}

- (void)performcallBackWithUserInfo:(NSDictionary *)userInfo
{
    self.isLoading = NO;
    if (self.errorType == GSRequestErrorTypeSuccess) {
        //cache
        if (self.cacheTimeInSeconds && self.cacheKey) {
            [self.cache saveCacheWithData:userInfo
                                cacheTime:self.cacheTimeInSeconds
                                serviceID:[NSString stringWithFormat:@"%x",[self.child serviceNumber]]
                              serviceType:self.serviceType
                        requestIdentifier:self.cacheKey];
        }
        
        [self beforePerformSuccessWithUserInfo:userInfo];
        //call back
        if ([self.delegate respondsToSelector:@selector(requestDidSucceed:userInfo:)]) {
            [self.delegate requestDidSucceed:self userInfo:userInfo];
        }
        if (self.successBlock) {
            self.successBlock(self, userInfo);
        }
        [self afterPerformSuccessWithUserInfo:userInfo];
    }
    else {
        [self beforePerformFailWithUserInfo:userInfo];
        if ([self.delegate respondsToSelector:@selector(requestDidFailed:userInfo:)]) {
            [self.delegate requestDidFailed:self userInfo:userInfo];
        }
        if (self.failBlock) {
            self.failBlock(self, userInfo);
        }
        [self afterPerformFailWithUserInfo:userInfo];
    }
    //解循环引用
    [self setCompletionBlockSuccess:nil failure:nil];
}

#pragma mark - AOP请求前后的拦截方法
- (void)beforePerformSuccessWithUserInfo:(NSDictionary *)userInfo
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(request:beforePerformSuccessWithUserInfo:)]) {
        [self.interceptor request:self beforePerformSuccessWithUserInfo:userInfo];
    }
}

- (void)afterPerformSuccessWithUserInfo:(NSDictionary *)userInfo
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(request:afterPerformSuccessWithUserInfo:)]) {
        [self.interceptor request:self afterPerformSuccessWithUserInfo:userInfo];
    }
}

- (void)beforePerformFailWithUserInfo:(NSDictionary *)userInfo
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(request:beforePerformFailWithUserInfo:)]) {
        [self.interceptor request:self beforePerformFailWithUserInfo:userInfo];
    }
}

- (void)afterPerformFailWithUserInfo:(NSDictionary *)userInfo
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(request:afterPerformFailWithUserInfo:)]) {
        [self.interceptor request:self afterPerformFailWithUserInfo:userInfo];
    }
}

- (void)beforePerformRequest
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(beforePerformRequest:)]) {
        [self.interceptor beforePerformRequest:self];
    }
}

- (void)afterPerformRequest
{
    if (self != self.interceptor && [self.interceptor respondsToSelector:@selector(afterPerformRequest:)]) {
        [self.interceptor afterPerformRequest:self];
    }
}

#pragma mark - Debug

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: serviceCmd: %@ serviceType: %d", [super description], self.serviceCmd, self.serviceType];
}

- (void)initDebugLabel
{
#if !GRAY_OR_APPSTORE
    dispatch_async(dispatch_get_main_queue(), ^{
        _debugLabel = [[GSDebugLabel alloc] init];
        [_debugLabel setPrefixStr:NSStringFromClass(self.class)];
        [_debugLabel sizeToFit];
    });
#endif
}

- (GSDebugLabel *)debugLabel
{
    if (!self.openDebugMode) {
        return nil;
    }
    return _debugLabel;
}

- (void)showDebugInfo:(NSString *)string
{
    FATLog(@"%@ - %@", self.description, string);
#if !GRAY_OR_APPSTORE
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.debugLabel setText:string];
    });
#endif
}

#pragma mark - 封包解包

- (void)willBeginSending
{
    [self showDebugInfo:@"Begin sending..."];
}

- (unsigned char *)getRequestBuffer
{
//    std::string *reqBodyStr = (std::string *)[self.child getRequestBodyString];
//    if (!reqBodyStr->length()) {
//        [self showDebugInfo:@"封包失败，请检查封包方法..."];
//        return nil;
//    }
//    tencent::im::oidb::OIDBSSOPkg pkg;
//    pkg.set_uint32_command([self.child serviceNumber]);
//    pkg.set_uint32_result(0);
//    pkg.set_uint32_service_type(self.serviceType);
//    pkg.set_bytes_bodybuffer(*reqBodyStr);
//    delete reqBodyStr;
//    
//    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
//    NSString *currentVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
//    if(currentVersion && currentVersion.length > 0) {
//        NSString *ver = [NSString stringWithFormat:@"ios %@", currentVersion];
//        pkg.set_bytes_client_version(std::string([ver UTF8String]));
//    }
//    
//    std::string strBuffer = PBProxy::addWupHead(&pkg);
//    
//    size_t length = strBuffer.size();
//    unsigned char *reqBuf = (unsigned char *)malloc(length);
//    memcpy(reqBuf, (unsigned char *)strBuffer.data(), length);
    unsigned char *reqBuf = 0;
    return reqBuf;
}

- (NSDictionary *)notifyRespBuffer:(const unsigned char *)buffer len:(int)len seq:(int)seq
{
    [self showDebugInfo:@"Request succeed."];
//    unsigned char* wupBuffer = PBProxy::removeWupHead((unsigned char *)buffer, len);
//    int bufferLength = len - WUP_HEAD_LENGTH;
//    
//    tencent::im::oidb::OIDBSSOPkg pkg;
//    
//    pkg.ParseFromArray(wupBuffer, bufferLength);
//    std::string respBodyStr = pkg.bytes_bodybuffer();
//    self.pkgResult = pkg.uint32_result();
//    if (self.pkgResult != 0) {
//        self.errorType = GSRequestErrorTypeLogicError;
//        
//        //按3个优先级获取错误信息 子类指定 > 包头 > 显示错误码
//        self.errorMessage = [self translateHeaderCode:self.pkgResult];
//        self.errorMessage = self.errorMessage.length ? self.errorMessage : [NSString stringWithUTF8String:pkg.str_error_msg().c_str()];
//        self.errorMessage = self.errorMessage.length ? self.errorMessage : [NSString stringWithFormat:@"网络请求失败：%d", self.pkgResult];
//        
//        [self showDebugInfo:[NSString stringWithFormat:@"Error: %x(%d) %@", self.pkgResult, self.pkgResult, self.errorMessage]];
//    }
//    if (respBodyStr.length()) {
//        return [self.child parseResponseBodyString:&respBodyStr];
//    }
//    else if (self.pkgResult == 0) {
//        self.errorType = GSRequestErrorTypeLogicError;
//        self.errorMessage = @"回包为空";
//        [self showDebugInfo:@"Empty reply."];
//    }
    return nil;
}

- (NSString *)translateHeaderCode:(uint32_t)headerResult
{
    return nil;
}


@end
