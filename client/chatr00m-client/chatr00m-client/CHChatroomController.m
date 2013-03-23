//
//  CHChatroomController.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/23/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHChatroomController.h"
#import "CHChatroomWindowController.h"

@implementation CHChatroomController


- (NSMutableArray *) windowControllers
{
    // lazy instantiation
    if (!_windowControllers) _windowControllers = [NSMutableArray array];
    return _windowControllers;
}

- (IBAction)newChatroom:(id)sender
{
    static int i = 0;
    
    CHChatroomWindowController *wc = [CHChatroomWindowController chatroomWindowControllerWithRoomId:i++];
    [self.windowControllers addObject:wc];
    [wc showWindow:self];
}

- (IBAction)showChatroom:(id)sender
{
    
}

- (CHChatroomWindowController *)chatroomWindowControllerForRoomId:(int)roomId
{
    // refactor with NSCache
    CHChatroomWindowController *resultWindowController;
    if (!resultWindowController) {
        NSArray *resultArr = [self.windowControllers filteredArrayUsingPredicate:
                              [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                                CHChatroomWindowController *wc = (CHChatroomWindowController *) evaluatedObject;
                                return wc.roomId == roomId;
                                }]];
        if (resultArr.count != 0) {
            resultWindowController = resultArr[0];
        }
    }
    
    return resultWindowController;
}

@end
