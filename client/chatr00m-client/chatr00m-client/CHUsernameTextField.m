//
//  CHUsernameTextField.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/16/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHUsernameTextField.h"

@implementation CHUsernameTextField

- (void)mouseDown:(NSEvent *)theEvent
{
    [self.actionDelegate usernameTextFieldIsClicked:self];
    /*
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert addButtonWithTitle:@"Change Username"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setInformativeText:@"You want to change something right?"];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:self.stringValue];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    
    if (button == NSAlertFirstButtonReturn) {
        [input validateEditing];
        self.stringValue = [input.stringValue copy];
        
    }
    //NSWindow *window = [[NSApplication sharedApplication] windows][0];
    //[alert beginSheetModalForWindow: window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    */
}

- (void)setStringValue:(NSString *)aString
{
    [super setStringValue:aString];
    [[CHCommunicationAgent sharedAgent] send:@{@"user_name": self.stringValue} forAction:ACTION_SETUSERNAME];   
}

@end
