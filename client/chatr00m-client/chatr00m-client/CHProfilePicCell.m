//
//  CHProfilePicCell.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/16/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHProfilePicCell.h"
#import "NSOpenPanel+CHOpenPanel.h"
#import "CHCommunicationAgent.h"

@implementation CHProfilePicCell

- (void)mouseDown:(NSEvent *)theEvent
{
    if (self.clicked) return;
    self.clicked = YES;
    NSLog(@"change profile pic");
    NSOpenPanel *openDialog = [NSOpenPanel openPanel];
    [openDialog setAllowedFileTypes:[NSImage imageTypes]];
    [openDialog setLevel:0];
    openDialog.canChooseFiles = YES;
    [openDialog beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *picURL = [openDialog URLs][0];
            NSLog(@"%@", picURL);
            self.image = [[NSImage alloc] initWithContentsOfURL:picURL];
            self.clicked = NO;
            // send new pic to server
            NSData *imageData = [NSData dataWithContentsOfURL:picURL];
            [[CHCommunicationAgent sharedAgent] sendFile:imageData];
        }
    }];
}


@end
