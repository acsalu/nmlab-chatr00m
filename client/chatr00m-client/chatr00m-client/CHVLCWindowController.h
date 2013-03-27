//
//  CHVLCWindowController.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/27/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VLCKit/VLCKit.h>

@interface CHVLCWindowController : NSWindowController

@property (weak) IBOutlet VLCVideoView *videoView;

@property (strong, nonatomic) VLCMedia *media;
@property (strong, nonatomic) VLCStreamSession *streamSession;
@property (strong, nonatomic) VLCMediaPlayer *mediaPlayer;
@property (strong, nonatomic) NSString *remoteURLAsString;

- (IBAction)play:(id)sender;

@end
