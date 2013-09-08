//
//  SHAudioPlayer.m
//  SHAudioPlayer
//
//  Created by shouian on 13/9/7.
//  Copyright (c) 2013年 shouian. All rights reserved.
//

#import "SHAudioPlayer.h"

// 3 is recommended by Apple
#define NUM_BUFFERS 3

static UInt32 gBufferSizeBytes = 0x10000; // It must be pow(2,x)

@interface SHAudioPlayer()
{
    // File ID
    AudioFileID audioFileID;
    // Description
    AudioStreamBasicDescription dataFormat;
    // Buffer Queue
    AudioQueueRef                   queueRef;
    SInt64                          packetIndex;
    UInt32                          numPacketsToRead;
    UInt32                          bufferByteSize;
    AudioStreamPacketDescription    *packetsDescs;
    AudioQueueBufferRef             buffers[NUM_BUFFERS];
}

// Read Buffer
- (void)audioQueueOutputWithQueue:(AudioQueueRef)audioQueue queueBuffer:(AudioQueueBufferRef)audioQueueBufferRef;

- (UInt32)readPacketsIntoBuffer:(AudioQueueBufferRef)buffer;

// Callback function (Standard format)
static void BufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef buffer);

@end

@implementation SHAudioPlayer

@synthesize queueRef;

// Init Player
- (id)initWithAudio:(NSString *)filePath
{
    self = [super init];
    if (self) {
        UInt32   size;
        UInt32   maxPacketSize;
        char     *cookie;
        OSStatus status;
        
        // Open File
        status = AudioFileOpenURL((CFURLRef)[NSURL fileURLWithPath:filePath], kAudioFileReadPermission, 0, &audioFileID);
        
        if (status != noErr) {
            NSLog(@"Error encounter when opening file %@", filePath);
            return nil;
        }
        
        // Read audio data format
        size = sizeof(dataFormat);
        AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &size, &dataFormat);
        
        // Create music queue for playing
        AudioQueueNewOutput(&dataFormat, BufferCallback, self, nil, nil, 0, &queueRef);
        
        // Calculate number of packets in unit time
        if (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0) {
            size = sizeof(maxPacketSize);
            AudioFileGetProperty(audioFileID, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
            
            if (maxPacketSize > gBufferSizeBytes) {
                maxPacketSize = gBufferSizeBytes;
            }
            // Calculation
            numPacketsToRead = gBufferSizeBytes / maxPacketSize;
            // Allocate size
            packetsDescs = malloc(sizeof(AudioStreamPacketDescription) * numPacketsToRead);
        } else {
            numPacketsToRead = gBufferSizeBytes / dataFormat.mBytesPerPacket;
            packetsDescs = nil;
        }
        
        // Set up Magic cookie
        AudioFileGetProperty(audioFileID, kAudioFilePropertyMagicCookieData, &size, nil);
        if (size > 0) {
            cookie = malloc(sizeof(char) * size);
            AudioFileGetProperty(audioFileID, kAudioFilePropertyMagicCookieData, &size, cookie);
            AudioQueueSetProperty(queueRef, kAudioQueueProperty_MagicCookie, cookie, size);
        }
        
        // Create and Allocate buffer size
        packetIndex = 0;
        for (int i = 0; i < NUM_BUFFERS; i++) {
            AudioQueueAllocateBuffer(queueRef, gBufferSizeBytes, &buffers[i]);
            // Read Packet data
            if ([self readPacketsIntoBuffer:buffers[i]] == 1) {
                break;
            }
        }
        Float32 gain = 1.0;
        // Set up volume
        AudioQueueSetParameter(queueRef, kAudioQueueParam_Volume, gain);
        // Start queue, and then OS will handle the callback
        AudioQueueStart(queueRef, nil);
        
    }
    return self;
}

- (void)dealloc
{ㄗ
    [super dealloc];
}

// Callback Implement
static void BufferCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef buffer)
{
    SHAudioPlayer *player = (SHAudioPlayer *)inUserData;
    [player audioQueueOutputWithQueue:inAQ queueBuffer:buffer];
}

// Read Buffer
- (void)audioQueueOutputWithQueue:(AudioQueueRef)audioQueue queueBuffer:(AudioQueueBufferRef)audioQueueBufferRef
{
    OSStatus status;
    
    // Read packet data
    UInt32 numBytes;
    UInt32 numPackets = numPacketsToRead;
    
    status = AudioFileReadPackets(audioFileID,
                                  NO,
                                  &numBytes,
                                  packetsDescs,
                                  packetIndex,
                                  &numPackets,
                                  audioQueueBufferRef->mAudioData);
    // When succeed to read
    if (numPackets > 0) {
        // Allocate buffer size as same as reading music buffer size
        audioQueueBufferRef->mAudioDataByteSize = numBytes;
        // Finish allocating queue
        status = AudioQueueEnqueueBuffer(audioQueue, audioQueueBufferRef, numPackets, packetsDescs);
        // Move Start index
        packetIndex += numPackets;
    }
}

- (UInt32)readPacketsIntoBuffer:(AudioQueueBufferRef)buffer
{
    // Read data and save it to buffer
    UInt32 numBytes;
    UInt32 numPackets = numPacketsToRead;
    AudioFileReadPackets(audioFileID,
                         NO,
                         &numBytes,
                         packetsDescs,
                         packetIndex,
                         &numPackets,
                         buffer->mAudioData);
    
    if (numPackets > 0) {
        buffer->mAudioDataByteSize = numBytes;
        AudioQueueEnqueueBuffer(queueRef, buffer, (packetsDescs ? numPackets : 0), packetsDescs);
        packetIndex += numPackets;
    } else {
        return 1; // Which means we do not accept any packet
    }
    return 0; // Normal resign
}

@end
