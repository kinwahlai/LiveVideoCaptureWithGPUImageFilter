//
//  ViewController.m
//  LiveVideoCaptureWithGPUImageFilter
//
//  Created by Kin Wah Lai on 10/11/12.
//  Copyright (c) 2012 kinwah. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()
{
    GPUImageVideoCamera *videoCamera;
    __weak IBOutlet GPUImageView *gpuImageView;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    filter = [[GPUImageSepiaFilter alloc] init];
    [videoCamera addTarget:filter];
    GPUImageView *filterView = gpuImageView;
    [filter addTarget:filterView];
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
    [filter addTarget:movieWriter];
    
    [videoCamera startCameraCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startRecording:(id)sender
{
    double delayToStartRecording = 0.1;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"Start recording");
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];
    });
}

- (IBAction)stopRecording:(id)sender
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"file.mov"];
    double delayInSeconds = 0.1;
    dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
        [filter removeTarget:movieWriter];
        videoCamera.audioEncodingTarget = nil;
        [movieWriter finishRecording];
        NSLog(@"Movie completed");
        ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
        [al writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:path] completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"Error %@", error);
            } else {
                NSLog(@"Success");
                //NSFileManager *fm = [NSFileManager defaultManager];
                //[fm removeItemAtPath:path error:&error];
            }
        }];
    });
}

@end
