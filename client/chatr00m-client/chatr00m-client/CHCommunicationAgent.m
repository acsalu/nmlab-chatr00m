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
#import "CHAppDelegate.h"
#import "CHChatroomController.h"
#import "CHChatroomWindowController.h"
#import <ifaddrs.h>

#define MAX_BUF_SIZE 200

NSString *const ACTION_SETUSERNAME = @"SET_USERNAME";
NSString *const ACTION_TALK = @"TALK";
NSString *const ACTION_NEWROOM = @"NEW_ROOM";
NSString *const ACTION_ROOMLIST = @"ROOM_LIST";

NSString *const ACTION_ENTERROOM = @"ENTER_ROOM";
NSString *const ACTION_LEAVEROOM = @"LEAVE_ROOM";

NSString *const ACTION_ASKTOSEND = @"ASKTOSEND";
NSString *const ACTION_AGREETORECEIVE = @"AGREETORECEIVE";


NSString *const ACTION_ROOMINFO = @"ONE_ROOM_INFO";
NSString *const ACTION_NEWMESSAGE = @"NEW_MESSAGE";

NSString *const ACTION_SETUSERPIC = @"SET_USERPIC";

const char *SERVER_IP = "54.249.234.231";
//const char *SERVER_IP = "140.112.18.220";

const int SERVER_PORT = 10627;

__strong id agent;

@implementation CHCommunicationAgent


+ (CHCommunicationAgent *)sharedAgent
{
    static dispatch_once_t pred = 0;
    __strong static id __communicationAgent = nil;
    dispatch_once(&pred, ^{
        __communicationAgent = [[self alloc] init];
        [__communicationAgent connect];
        agent = __communicationAgent;
    });
    return __communicationAgent;
}

- (void)connect
{
    if (self.socket) {
        CFSocketInvalidate(self.socket);
        CFRelease(self.socket);
        self.socket = NULL;
    }
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
    addr.sin_addr.s_addr = inet_addr(SERVER_IP);
    addr.sin_port = htons(SERVER_PORT);
    
    CFDataRef address = CFDataCreate(kCFAllocatorDefault, (const UInt8*)&addr, sizeof(addr));
    
    if (CFSocketConnectToAddress(socket, address, -1) < 0) {
        NSLog(@"fuck");
    }
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
    CFRunLoopAddSource(runloop, source, kCFRunLoopCommonModes);
    CFRelease(source);
    
    [self setSocket:socket];
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
//    const char *msg = [[dic JSONString] cStringUsingEncoding:NSUTF8StringEncoding];
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
//        printf("data length = %ld\n", CFDataGetLength((CFDataRef)dataPtr)); 
        // handle your data here. This example prints to stderr.
        char *someBuf;
        if ((someBuf = malloc(dataSize+1)) != nil) {
            for (size_t i = 0; i < dataSize; ++i)
                someBuf[i] = *(((const char*) CFDataGetBytePtr((CFDataRef) dataPtr)) + i);
            someBuf[dataSize] = '\0';
            printf("-------------------------------------------------------------\n");
            printf("SocketUtils: socket received:\n|%s|\n\n",someBuf);
            NSDictionary *dic = [[NSString stringWithUTF8String:someBuf] objectFromJSONString];
            
            NSString *action = dic[@"action"];
            NSDictionary *content = dic[@"content"];
            CHAppDelegate *appDelegate = (CHAppDelegate *) [NSApplication sharedApplication].delegate;
            CHChatroomController *cc = appDelegate.chatroomController;
            
            if ([action isEqualToString:ACTION_TALK] || [action isEqualToString:ACTION_ROOMINFO]) {
                int room_id = [content[@"room_id"] intValue];
                if (room_id == 0) {
                    [appDelegate communicationAgent:agent receiveMessage:dic];
                } else {
                    CHChatroomWindowController *wc = [cc chatroomWindowControllerForRoomId:room_id];
                    if (wc) {
                        [wc communicationAgent:agent receiveMessage:dic];
                    } else {
                        NSLog(@"No room with id %d", room_id);
                        //exit(1);
                    }
                }
            } else if ([action isEqualToString:ACTION_NEWROOM] ||
                       [action isEqualToString:ACTION_ENTERROOM] ||
                       [action isEqualToString:ACTION_NEWMESSAGE]) {
                [cc communicationAgent:agent receiveMessage:dic];
            } else if ([action isEqualToString:ACTION_ROOMLIST]) {
                [appDelegate communicationAgent:agent receiveMessage:dic];
            }
            
            free(someBuf);
        }
    }
}

- (void)send:(NSDictionary *)content forAction:(NSString *)action
{
    NSDictionary *dic = @{@"action":action, @"content":content};
    const char *msg = [[dic JSONString] cStringUsingEncoding:NSUTF8StringEncoding];
    send(CFSocketGetNative(self.socket), msg, strlen(msg) + 1, 0);
}

+ (NSString *)getIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                
                //if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                NSLog(@"%@ %@", [NSString stringWithUTF8String:temp_addr->ifa_name], [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]);
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                //}
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}

@end
