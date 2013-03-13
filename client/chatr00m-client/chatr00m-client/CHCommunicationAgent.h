//
//  CHCommunicationAgent.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CHCommunicationAgentDelegate;


@interface CHCommunicationAgent : NSObject

@property (nonatomic) int socket;

@property (weak) id<CHCommunicationAgentDelegate> delegate;

+ (CHCommunicationAgent *)sharedAgent;
- (void)sendMessage:(NSString *)message;
- (void)startReading;


@end

@protocol CHCommunicationAgentDelegate <NSObject>

@required
- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSString *)message;

@end

