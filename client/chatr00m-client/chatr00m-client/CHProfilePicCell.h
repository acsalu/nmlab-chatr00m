//
//  CHProfilePicCell.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/16/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CHProfilePicCell;

@protocol CHProfilePicCellDelegate <NSObject>

- (void) profilePicCell:(CHProfilePicCell *)profilePicCell isClicked:(BOOL)clicked;

@end

@interface CHProfilePicCell : NSImageView <NSPopoverDelegate>

@property (nonatomic) BOOL clicked;
@property (nonatomic) NSInteger profilePic;

@property (weak) IBOutlet id<CHProfilePicCellDelegate> delegate;


+ (NSImage *)profilePicForIndex:(int)index;

@end
