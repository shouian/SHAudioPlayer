//
//  SHAudioPlayer.h
//  SHAudioPlayer
//
//  Created by shouian on 13/9/7.
//  Copyright (c) 2013年 shouian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioFile.h>

@interface SHAudioPlayer : NSObject

@property (nonatomic) AudioQueueRef queueRef;

// Play method
- (id)initWithAudio:(NSString *)filePath;

@end
