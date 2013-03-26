//
//  CHAppDelegate.h
//  NSstreamTest
//
//  Created by Vincent on 13/3/26.
//  Copyright (c) 2013年 Vincent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHAppDelegate : NSObject <NSApplicationDelegate,NSStreamDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (retain, nonatomic) NSOutputStream *outputstream;
@property (retain, nonatomic) NSInputStream *inputstream;

- (void)initNetworkCommunication;
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
- (void)messageReceived:(NSString *)message;

@end
