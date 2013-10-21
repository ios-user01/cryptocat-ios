//
//  TBChatViewController.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 16/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TBChatViewControllerDelegate;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBChatViewController : UIViewController

@property (nonatomic, weak) id <TBChatViewControllerDelegate> delegate;

@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSMutableArray *usernames;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol TBChatViewControllerDelegate <NSObject>

- (void)chatViewController:(TBChatViewController *)controller
       didAskToSendMessage:(NSString *)message;
- (void)chatViewController:(TBChatViewController *)controller
       didAskToSendMessage:(NSString *)message
                    toUser:(NSString *)recipient;
@end