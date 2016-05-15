//
//  GSLBSRequest.h
//  QQMSFContact
//
//  Created by Fanta Xu on 15/11/23.
//
//

#import "GSBaseRequest.h"

@interface GSLocation : NSObject

@property (nonatomic, assign) int   longitude;
@property (nonatomic, assign) int   latitude;
@property (nonatomic, assign) int   altitude;
@property (nonatomic, assign) long  accuracy;

@end

@interface GSLBSRequest : GSBaseRequest

@property (nonatomic, strong) GSLocation *location;

/**
 *  当未获得定位授权时是否继续 YES则弹窗请求授权后继续 NO则取消请求。默认为YES
 *
 *  @return YES or NO
 */
- (BOOL)shouldRequestAuthorization;

/**
 *  请求不到LBS定位信息的情况下是否依然发送 默认为NO
 *
 *  @return YES or NO
 */
- (BOOL)shouldRequestWhenLBSFailed;

@end
