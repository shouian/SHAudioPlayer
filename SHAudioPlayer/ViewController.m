//
//  ViewController.m
//  SHAudioPlayer
//
//  Created by shouian on 13/9/7.
//  Copyright (c) 2013年 shouian. All rights reserved.
//

#import "ViewController.h"
#import "SHAudioPlayer.h"

@interface ViewController ()
{
    SHAudioPlayer *audioPlayer;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    audioPlayer = [[SHAudioPlayer alloc] initWithAudio:@"/Users/shouian/Desktop/AppDev/AppCodeDevelop/SHAudioPlayer/brave.mp3"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
