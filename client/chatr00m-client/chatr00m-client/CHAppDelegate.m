//
//  CHAppDelegate.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHAppDelegate.h"
#import "CHCommunicationAgent.h"
#import <CoreAudio/CoreAudio.h>

@implementation CHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.agent = [CHCommunicationAgent sharedAgent];
    self.agent.delegate = self;
    //[self.agent startReading];
    
}

- (IBAction)send:(id)sender {
    [self.agent sendMessage:self.messageTextField.stringValue];
    self.messageTextField.stringValue = @"";
}

- (IBAction)transferFile:(id)sender
{
    NSOpenPanel *openDialog = [NSOpenPanel openPanel];
    openDialog.canChooseFiles = YES;
    openDialog.allowsMultipleSelection = YES;
    if ([openDialog runModal]) {
        for (NSURL *url in [openDialog URLs]) {
            NSLog(@"select file %@", url);
        }
    }
}

- (IBAction)openCamera:(id)sender {
}

- (IBAction)openMic:(id)sender {
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if ([[[obj userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
    {
        [self send:nil];
    }
}

- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSString *)message
{
//    NSRange end = NSMakeRange(self.messageBoard.string.length, 0);
//    end.location += message.length;
//    if (NSMaxY([self.messageBoard visibleRect]) == NSMaxY([self.messageBoard bounds])) {
//        self.messageBoard.string = [NSString stringWithFormat:@"%@\n%@",  self.messageBoard.string, message];
//        [self.messageBoard scrollRangeToVisible:end];
//    } else {
        self.messageBoard.string = [NSString stringWithFormat:@"%@\n%@",  self.messageBoard.string, message];
//    }
 
}


@end
