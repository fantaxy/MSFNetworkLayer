//
//  GSLBSRequest.m
//  QQMSFContact
//
//  Created by Fanta Xu on 15/11/23.
//
//

#import "GSLBSRequest.h"
#import "QQLBSServerEngine.h"

#if !__has_feature(objc_arc)
#error  does not support Objective-C Automatic Reference Counting (ARC)
#endif

@implementation GSLocation
- (NSString *)description
{
    return CZ_NSString_stringWithFormat(@"longitude = %d, latitude = %d, altitude = %d, accuracy = %ld", self.longitude, self.latitude, self.altitude, self.accuracy);
}

@end

@implementation GSLBSRequest

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

- (BOOL)shouldRequestAuthorization
{
    return YES;
}

- (BOOL)shouldRequestWhenLBSFailed
{
    return NO;
}

- (void)load
{
    [[QQLBSServerEngine instance] isEnabledAndAuthorizeCallBack:^( BOOL isAuthorized ) {
        QLog_Event(MODULE_IMPB_SAMREQENGINE, "%s: isAuthorized: %d", __FUNCTION__, isAuthorized);
        
        if ( ![self shouldRequestAuthorization] && !isAuthorized ) {
            //未授权且请求指定不触发弹窗询问
            QLog_Event(MODULE_IMPB_SAMREQENGINE, "%s: lbs is disable or no authorize cmd: %s", __FUNCTION__, self.serviceCmd.UTF8String);
            
            if (![self shouldRequestWhenLBSFailed]) {
                self.errorType = GSRequestErrorTypeLBSFailed;
                self.errorMessage = @"定位请求失败，未取得授权。";
                [self showDebugInfo:self.errorMessage];
                
                [self callBackWithUserInfo:nil];
            }
            else {
                [super load];                
            }
        } else {
            CZ_AddObj2DeftNotiCenter(self, @selector(notifyLbsEndUpdateLocation:), QQLbsEndUpdateLocationNotification, nil);
            [[QQLBSServerEngine instance] startUpdateGPSLocation:[self class]];
        }
    }];
    
}

- (void)loadWithoutCache
{
    [self load];
}

- (void) notifyLbsEndUpdateLocation:(NSNotification *)notifiy
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:QQLbsEndUpdateLocationNotification object:nil];
    
    NSDictionary *userInfo = (NSDictionary *)[notifiy userInfo];
    if ( userInfo ) {
        int result = [userInfo intForKey:LbsEndUpdateLocationKey_Result];
        switch (result) {
            case NOTIFY_RESULT_SUCCESS:
            {
                QLog_Event(MODULE_IMPB_SAMREQENGINE, "%s: lbs result is success", __FUNCTION__);
                GSLocation *location = [GSLocation new];
                location.longitude = [userInfo intForKey:LbsEndUpdateLocationKey_Lon];
                location.latitude  = [userInfo intForKey:LbsEndUpdateLocationKey_Lat];
                location.altitude  = [userInfo intForKey:LbsEndUpdateLocationKey_Alt];
                location.accuracy = [[userInfo objectForKey:LbsEndUpdateLocationKey_Accuracy] longLongValue];
                self.location = location;
                
                [super load];
            }
                break;
            case NOTIFY_RESULT_ERROR:
            {
                QLog_Event(MODULE_IMPB_SAMREQENGINE, "%s: lbs result is error", __FUNCTION__);
                
                [[QQLBSServerEngine instance] isEnabledAndAuthorizeCallBack:^(BOOL isAuthorized) {
                    QLog_Event(MODULE_IMPB_SAMREQENGINE, "%s: isAuthorized: %d", __FUNCTION__, isAuthorized);
                    
                    if ( !isAuthorized ) {
                        if ([self shouldRequestWhenLBSFailed]) {
                            [super load];
                        }
                        else {
                            self.errorType = GSRequestErrorTypeLBSFailed;
                            self.errorMessage = @"定位请求失败，未取得授权。";
                            
                            [self callBackWithUserInfo:nil];
                        }
                    } else {
                        
                        if ([self shouldRequestWhenLBSFailed]) {
                            [super load];
                        }
                        else {
                            self.errorType = GSRequestErrorTypeLBSFailed;
                            self.errorMessage = @"定位请求失败。";
                            
                            [self callBackWithUserInfo:nil];
                        }                        
                    }
                }];
            }
                break;
            default:
                break;
        }
    }
}

@end
