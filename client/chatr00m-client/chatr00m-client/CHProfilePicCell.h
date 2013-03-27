//
//  CHProfilePicCell.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/16/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHProfilePicCell : NSImageView <NSPopoverDelegate>

@property (nonatomic) BOOL clicked;
@property (nonatomic) NSInteger profilePic;

@end
