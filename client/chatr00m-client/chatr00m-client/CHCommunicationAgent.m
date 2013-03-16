//
//  CHCommunicationAgent.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHCommunicationAgent.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <sys/un.h>
#import <arpa/inet.h>
#import <netdb.h>
#include <sys/types.h>
#include <unistd.h>
#import "JSONKit.h"


#define MAX_BUF_SIZE 1024

__strong id agent;

@implementation CHCommunicationAgent


+ (CHCommunicationAgent *)sharedAgent
{
    static dispatch_once_t pred = 0;
    __strong static id __communicationAgent = nil;
    dispatch_once(&pred, ^{
        __communicationAgent = [[self alloc] init];
        
        struct sockaddr_in addr;
        
        CFSocketRef socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, 0, kCFSocketDataCallBack, SocketDataCallBack, NULL);
        if (!socket) {
            NSLog(@"Socket creation failed");
            exit(1);
        }
        
        int yes = 1;
        if (setsockopt(CFSocketGetNative(socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(int))) {
            NSLog(@"sesockopt failed");
            CFRelease(socket);
            exit(1);
        }
        
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(struct sockaddr_in);
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = inet_addr("140.112.18.220");
        addr.sin_port = htons(10627);
        
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (const UInt8*)&addr, sizeof(addr));
        
        if (CFSocketConnectToAddress(socket, address, -1) < 0) {
            NSLog(@"fuck");
        }
        CFRunLoopRef runloop = CFRunLoopGetCurrent();
        CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
        CFRunLoopAddSource(runloop, source, kCFRunLoopCommonModes);
        CFRelease(source);
    
        [__communicationAgent setSocket:socket];
        agent = __communicationAgent;
    });
    return __communicationAgent;
}


- (void)sendFile:(NSData *)data
{
    struct sockaddr_in addr;
    
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(struct sockaddr_in);
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr("140.112.18.220");
    addr.sin_port = htons(10627);
    
    CFDataRef address = CFDataCreate(kCFAllocatorDefault, (const UInt8*)&addr, sizeof(addr));
    NSDictionary *dic = @{@"action":@"CHANGE_PIC", @"content": data};
    const char *msg = [[dic JSONString] cStringUsingEncoding:NSUTF8StringEncoding];
    //send(CFSocketGetNative(self.socket), msg, strlen(msg) + 1, 0);
    
    if (CFSocketSendData(self.socket, address, CFDataCreate(NULL, [data bytes], [data length]), 0)) {
        NSLog(@"file transfer sucks");
    }
}

void SocketDataCallBack (CFSocketRef sock,
                         CFSocketCallBackType type,
                         CFDataRef theAddr,
                         const void * dataPtr,
                         void * info)
{
    CFIndex dataSize;
    
    if ((dataSize = CFDataGetLength((CFDataRef)dataPtr)) > 0) {
        printf("data length = %ld\n", CFDataGetLength((CFDataRef)dataPtr)); 
        // handle your data here. This example prints to stderr.
        char *someBuf;
        if ((someBuf = malloc(dataSize+1)) != nil) {
            for (size_t i = 0; i < dataSize; ++i)
                someBuf[i] = *(((const char*) CFDataGetBytePtr((CFDataRef) dataPtr)) + i);
            someBuf[dataSize] = '\0';
            printf("SocketUtils: socket received:\n|%s|\n",someBuf);
            [((CHCommunicationAgent *)agent).delegate communicationAgent:agent receiveMessage:[NSString stringWithCString:someBuf encoding:NSUTF8StringEncoding]];
            free(someBuf);
        }
        
        // we'll also send a response
        /*
        if ((dataOut = CFDataCreate(kCFAllocatorDefault,
                                    (const UInt8 *) stringOut,
                                    strlen(stringOut))) != nil) {
            CFSocketSendData(sock,NULL,dataOut,0);
            CFRelease(dataOut);
        };
         */
    }
    //CFSocketInvalidate(sock);
    //CFRelease(sock);

    //printf("data length = %ld\n", CFDataGetLength((CFDataRef)dataPtr));
}

- (void)sendMessage:(NSString *)message
{
    NSDictionary *dic = @{@"action":@"TALK", @"content": message};
    const char *msg = [[dic JSONString] cStringUsingEncoding:NSUTF8StringEncoding];
    send(CFSocketGetNative(self.socket), msg, strlen(msg) + 1, 0);
}

@end
