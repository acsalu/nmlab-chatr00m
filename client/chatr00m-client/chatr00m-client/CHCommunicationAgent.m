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

#define MAX_BUF_SIZE 1024

@implementation CHCommunicationAgent


+ (CHCommunicationAgent *)sharedAgent
{
    static dispatch_once_t pred = 0;
    __strong static id __communicationAgent = nil;
    dispatch_once(&pred, ^{
        __communicationAgent = [[self alloc] init];
        struct sockaddr_in serv_name;
        serv_name.sin_family = AF_INET;
        serv_name.sin_addr.s_addr = inet_addr("140.112.18.220");
        serv_name.sin_port = htons(atoi("10627"));
        
        int clientSocket = socket(AF_INET, SOCK_STREAM, 0);
        if (clientSocket == -1) {
            NSLog(@"Socket creation failed");
            exit(1);
        }
        [__communicationAgent setSocket: clientSocket];
        
        int status = connect(clientSocket, (struct sockaddr *)&serv_name, sizeof(serv_name));
        if (status == -1) {
            NSLog(@"Connection error");
            exit(1);
        } else {
            NSLog(@"Connection succeed");
        }

    });
    return __communicationAgent;
}

- (void)sendMessage:(NSString *)message
{
    const char *msg = [message cStringUsingEncoding:NSUTF8StringEncoding];
    writef(self.socket, "%s", msg);
}

void writef(int socket, const char *format, ...)
{
    char buffer[MAX_BUF_SIZE];
    va_list args;
    va_start(args, format);
    int length = vsprintf(buffer, format, args);
    va_end(args);
    write(socket, buffer, length);
}

@end
