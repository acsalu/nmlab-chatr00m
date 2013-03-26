//
//  CHCommunicationAgent.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>

extern NSString *const ACTION_TALK;
extern NSString *const ACTION_NEWROOM;

@protocol CHCommunicationAgentDelegate;


@interface CHCommunicationAgent : NSObject

@property (nonatomic) CFSocketRef socket;

@property (weak) id<CHCommunicationAgentDelegate> delegate;

+ (CHCommunicationAgent *)sharedAgent;
- (void)connect;

- (void)sendMessage:(NSString *)message;
- (void)send:(NSDictionary *)content forAction:(NSString *)action;

- (void)sendFile:(NSData *)data;
- (void)setUserName:(NSString *)name;
- (void)newRoom:(NSString *)roomName;
- (void)enterRoom:(NSString *)roomName;
- (void)leaveRoom:(NSString *)roomName;
- (void)setPicture:(NSImage *)picture;


+ (NSString *)getIPAddress;

@end

@protocol CHCommunicationAgentDelegate <NSObject>

@optional
//- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSString *)message;
- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSDictionary *)dic;

@end

