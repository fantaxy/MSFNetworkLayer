//
//  IMSFDelegate.h
//  QQMSFContact
//
//  Created by jon tan on 12-5-29.
//  Copyright (c) 2012年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol IMSFDelegate<NSObject>
@optional
//! 透传结果通知
- (void)OnMSFRecvDataFromBackend:(NSString *)aCmd buf:(NSData *)aData seq:(NSNumber *)aSeq;
//! SSO下发的A2错误通知
- (void)OnMSFSSOErrorStateResult:(NSDictionary*)aDict;
//! 网络状态的通知，包括以下情况：
//  1 即将进行连接
//  2 连接上
//  3 断开连接
- (void)OnMSFNetworkState:(NSDictionary*)aDict;
//! 网络可达不可达的状态通知，包括以下情况：
//  1 将所有ip都轮了一遍都连不上的通知（这个情况严格的说不是网络可达或不可达的状态）
//  2 网络变的可达
//  3 网络变的不可达
- (void)OnMSFApnState:(NSDictionary*)aDict;

- (void)OnMSFPacketState:(NSDictionary*)aDict;

//! 流量通知，包括：
//  1 写入socket字节时的通知
//  2 从socket读到字节时的通知
- (void)OnMSFSocketFlow:(NSArray*)aDictArray;
//
- (void)OnMSFIllegalGrayApp:(NSDictionary*)aDict;
- (void)OnMSFMsg:(NSDictionary*)aDict;

- (void)onMSFServerTimeUpdated:(NSDictionary*)aDict;

///msf http请求状态变化回调
- (void)onHTTPStatus:(NSDictionary*)aDict;
@end


