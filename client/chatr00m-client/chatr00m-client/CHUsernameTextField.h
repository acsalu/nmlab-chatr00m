//
//  CHUsernameTextField.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/16/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHCommunicationAgent.h"

@class CHUsernameTextField;

@protocol CHUsernameTextFieldDelegate <NSObject>

- (void)usernameTextFieldIsClicked:(CHUsernameTextField *)usernameTextField;

@end

@interface CHUsernameTextField : NSTextField

@property (weak) IBOutlet id<CHUsernameTextFieldDelegate> actionDelegate;

@end
