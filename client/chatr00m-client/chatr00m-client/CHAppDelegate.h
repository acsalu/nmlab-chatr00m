//
//  CHAppDelegate.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CHCommunicationAgent;
@protocol CHCommunicationAgentDelegate;

@interface CHAppDelegate : NSObject <NSApplicationDelegate, NSTextFieldDelegate, CHCommunicationAgentDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *messageTextField;
@property (weak) CHCommunicationAgent* agent;
@property (unsafe_unretained) IBOutlet NSTextView *messageBoard;

- (IBAction)send:(id)sender;
- (IBAction)transferFile:(id)sender;
- (IBAction)openCamera:(id)sender;
- (IBAction)openMic:(id)sender;


@end
