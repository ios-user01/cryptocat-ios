//
//  TBXMPPMessagesHandler.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 01/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TBMessagingProtocol;
extern NSString * const TBDidReceiveGroupChatMessageNotification;
extern NSString * const TBDidReceivePrivateChatMessageNotification;

@class TBXMPPManager, TBOTRManager, TBMultipartyProtocolManager, XMPPMessage, XMPPJID;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBXMPPMessagesHandler : NSObject

- (id)initWithOTRManager:(TBOTRManager *)OTRManager
multipartyProtocolManager:(TBMultipartyProtocolManager *)multipartyProtocolManager;
- (void)handleMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)sendMessageWithBody:(NSString *)body
                  recipient:(NSString *)recipient
                XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)sendGroupMessage:(NSString *)message XMPPManager:(TBXMPPManager *)XMPPManager;

@end