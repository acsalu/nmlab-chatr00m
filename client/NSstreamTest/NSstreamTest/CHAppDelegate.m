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
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"jpg",@"gif",@"png",nil];
    
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsOtherFileTypes:fileTypesArray];
    [openDlg setAllowsMultipleSelection:NO];
    
    NSString *filepath;

    if([openDlg runModal] == NSOKButton){
        NSLog(@"file chose");
        NSArray *files = [openDlg URLs];
        NSLog(@"array:%@",files);
        NSLog(@"filename:%@",[[files objectAtIndex:0] path]);
        filepath = [[files objectAtIndex:0] path];

    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:filepath];
    NSLog(@"image:%@",image);
    [image lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0,0,image.size.width,image.size.height)];
    [image unlockFocus];
    NSLog(@"bitmap:%@",bitmapRep);
    NSData *imageData = [bitmapRep representationUsingType:NSPNGFileType properties:Nil];
    NSLog(@"data:%@",imageData);
    NSHost *host = [NSHost hostWithAddress:@"140.112.18.221"];
    NSLog(@"connecting");
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)@"140.118.18.221", 80, &readStream, &writeStream);
    self.inputstream = (__bridge NSInputStream *)readStream;
    self.outputstream = (__bridge NSOutputStream *)writeStream;
    [self.inputstream setDelegate:self];
    [self.outputstream setDelegate:self];
    [self.inputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputstream open];
    [self.outputstream open];
    NSString *response = [NSString stringWithFormat:@"testing"];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [self.outputstream write:[data bytes] maxLength:[data length]];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"stream event %li", eventCode);
	
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
