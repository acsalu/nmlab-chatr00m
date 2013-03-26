//
//  CHAppDelegate.m
//  NSstreamTest
//
//  Created by Vincent on 13/3/26.
//  Copyright (c) 2013年 Vincent. All rights reserved.
//

#import "CHAppDelegate.h"

@implementation CHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self initNetworkCommunication];
    
}

- (void)initNetworkCommunication
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSHost *host = [NSHost hostWithAddress:@"140.112.18.211"];
    NSLog(@"host:%@",host);
    NSLog(@"connecting");
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(host), 10627, &readStream, &writeStream);
    self.inputstream = (__bridge NSInputStream *)readStream;
    self.outputstream = (__bridge NSOutputStream *)writeStream;
    [self.inputstream setDelegate:self];
    [self.outputstream setDelegate:self];
    [self.inputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"stream event %i", eventCode);
	
	switch (eventCode) {
			
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
		case NSStreamEventHasBytesAvailable:
            
			if (aStream == self.inputstream) {
				
				uint8_t buffer[1024];
				int len;
				
				while ([self.inputstream hasBytesAvailable]) {
					len = [self.inputstream read:buffer maxLength:sizeof(buffer)];
					if (len > 0) {
						
						NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
						
						if (nil != self.outputstream) {
                            
							NSLog(@"server said: %@", output);
							[self messageReceived:output];
							
						}
					}
				}
			}
			break;
            
			
		case NSStreamEventErrorOccurred:
			
			NSLog(@"Can not connect to the host!");
			break;
			
		case NSStreamEventEndEncountered:
            
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            aStream = nil;
			
			break;
		default:
			NSLog(@"Unknown event");
	}
}

- (void)messageReceived:(NSString *)message
{
    NSLog(@"message received...");
}


@end
