//
//  CHCommunicationAgent.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHCommunicationAgent : NSObject

@property (nonatomic) int socket;

+ (CHCommunicationAgent *)sharedAgent;
- (void)sendMessage:(NSString *)msg;


@end
