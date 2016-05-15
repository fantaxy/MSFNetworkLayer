//
//  GSBaseRequest.h
//  QQMSFContact
//
//  Created by Fanta Xu on 15/11/21.
//
//

#import <Foundation/Foundation.h>

@class GSBaseRequest;
typedef void (^GSRequestCallBack) (GSBaseRequest *request, NSDictionary *userInfo);

typedef NS_ENUM (NSUInteger, GSRequestErrorType){
    GSRequestErrorTypeDefault,       //没有产生过API请求，默认状态
    GSRequestErrorTypeSuccess,       //API请求成功且返回数据正确
    GSRequestErrorTypeLogicError,    //API请求成功但返回数据不正确 如回包解析失败（包头返回码不为0时）或者业务逻辑错误
    GSRequestErrorTypeParamsError,   //参数错误，不会发起网络请求 假如参数是用户填写 则可能出现
    GSRequestErrorTypeTimeout,       //请求超时
    GSRequestErrorTypeNoNetWork,     //网络不通
    GSRequestErrorTypeLBSFailed,     //LBS定位请求失败
};

@protocol GSRequestProtocol <NSObject>

@required
- (uint32_t)serviceNumber;
/**
 *  获取请求包体的序列化字符串 new std::string(req.SerializeAsString())
 *
 *  @return 类型：std::string *
 *
 包头已经在基类中解析，子类只需负责解析包体
 示例：
 using namespace tencent::im::oidb;
 cmd0x89b::ReqBody req;
 req.set_uint64_group_code(self.groupCode);
 return new std::string(req.SerializeAsString());
 */
- (void *)getRequestBodyString;
/**
 *  解析回包的序列化字符串 RspBody.ParseFromString()
 *
 *  @param string 类型：std::string *
 *
 *  @return 解析结果字典
 *
 包头已经在基类中解析，子类只需负责解析包体
 示例：
 using namespace tencent::im::oidb;
 cmd0x89b::RspBody resp;
 std::string *respBodyStr = (std::string *)string;
 int ret = resp.ParseFromString(*respBodyStr);
 if (ret) {
 }
 */
- (NSDictionary *)parseResponseBodyString:(void *)string;

@end

@protocol GSRequestCallBackDelegate <NSObject>

@optional
- (void)requestDidSucceed:(GSBaseRequest *)request userInfo:(NSDictionary *)userInfo;
- (void)requestDidFailed:(GSBaseRequest *)request userInfo:(NSDictionary *)userInfo;

@end

@protocol GSRequestInterceptor <NSObject>

@optional
- (void)request:(GSBaseRequest *)request beforePerformSuccessWithUserInfo:(NSDictionary *)userInfo;
- (void)request:(GSBaseRequest *)request afterPerformSuccessWithUserInfo:(NSDictionary *)userInfo;
- (void)request:(GSBaseRequest *)request beforePerformFailWithUserInfo:(NSDictionary *)userInfo;
- (void)request:(GSBaseRequest *)request afterPerformFailWithUserInfo:(NSDictionary *)userInfo;
- (void)beforePerformRequest:(GSBaseRequest *)request;
- (void)afterPerformRequest:(GSBaseRequest *)request;

@end

@interface GSBaseRequest : NSObject

///在发起请求前设置好serviceType 或者重写getter方法
@property (nonatomic, copy) NSString *serviceCmd;
@property (nonatomic, assign) uint32_t serviceType;
@property (nonatomic, weak) id<GSRequestCallBackDelegate> delegate;
@property (nonatomic, weak) id<GSRequestInterceptor> interceptor;

///请求发起时生成的请求ID 可用于取消请求 当前一个request实例只支持一个requestID （理论上同一个请求可发起多次，但似乎没什么必要）
@property (nonatomic, assign) NSNumber *requestID;

@property (nonatomic, copy) GSRequestCallBack successBlock;
@property (nonatomic, copy) GSRequestCallBack failBlock;

/// controller将通过errorType和errorMessage来提示用户
/// 为了保证这两个属性对外只读 派生类如果有额外的业务相关的错误信息 需要通过extension获得errorMessage的写权限
@property (nonatomic, assign) GSRequestErrorType errorType;
@property (nonatomic, copy) NSString *errorMessage;
@property (nonatomic, assign) BOOL isLoading;
///基类在解析包头时 会把包头返回码存到pkgResult中
@property (nonatomic, assign) uint32_t pkgResult;

///是否开启debug模式
@property (nonatomic, assign) BOOL openDebugMode;

///请求发起方法 如果你实现了GSRequestCallBackDelegate代理 那么直接使用load方法发起请求
- (void)load;
///如果不想实现代理方法 可以通过block方式发起请求
- (void)loadWithCompletionBlockSuccess:(void (^)(GSBaseRequest *request, NSDictionary *userInfo))success
                                failure:(void (^)(GSBaseRequest *request, NSDictionary *userInfo))failure;
///强制发起请求 不使用本地缓存
- (void)loadWithoutCache;
- (void)cancel;

///检查网络是否可达
- (BOOL)isReachable;

///指定是否在主线程回包
- (BOOL)shouldCallBackOnMainThread;

///子类如需要缓存需要一并重载cacheTimeInSeconds和cacheKey两个方法
- (BOOL)shouldCache;
///子类重载以设置缓存时间
- (NSInteger)cacheTimeInSeconds;
///子类重载 用来唯一标识缓存数据 一般使用参数组成的字符串
- (NSString *)cacheKey;

/**
 *  解析回包包头的错误码，子类重载并返回对应的错误提示
 *  errorMessage赋值优先级：1.子类在此方法返回的错误信息 2.包头str_error_msg字段值 3.hardcode的@"网络请求失败+错误码"
 *
 *  @param headerResult 包头返回码
 *
 *  @return 返回码对应的错误信息
 */
- (NSString *)translateHeaderCode:(uint32_t)headerResult;

/**
 *  控制是否做持久化 每次请求会将数据落地 并且第一次请求会先返回本地数据 再发起请求
 *  @return 默认返回NO 子类可重载
 */
//- (BOOL)shouldPersistance;

/**
 *  有些请求除了在初始化时指定好的参数外，还需要一些动态可变的参数，例如翻页请求
 *  该方法用于给继承的类做重载，在请求起飞之前额外添加一些参数,但不应该在这个函数里面修改已有的参数。
 */
- (void)addAdditionalParameters;

//AOP 拦截器方法 内部拦截使用派生类重载以下方法  外部拦截使用interceptor做拦截对象
- (void)beforePerformSuccessWithUserInfo:(NSDictionary *)userInfo;
- (void)afterPerformSuccessWithUserInfo:(NSDictionary *)userInfo;
- (void)beforePerformFailWithUserInfo:(NSDictionary *)userInfo;
- (void)afterPerformFailWithUserInfo:(NSDictionary *)userInfo;
- (void)beforePerformRequest;
- (void)afterPerformRequest;

///private method
- (unsigned char *) getRequestBuffer;
- (NSDictionary *) notifyRespBuffer:(const unsigned char *)buffer len:(int)len seq:(int)seq;
- (void)callBackWithUserInfo:(NSDictionary *)userInfo;
- (void)showDebugInfo:(NSString *)string;

@end
