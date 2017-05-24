//
//  ViewController.h
//  Fixcamera
//
//  Created by ghm on 16/10/6.
//  Copyright © 2016年 ghm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RBManager.h"
#import "RBPublisher.h"
#import "RBSubscriber.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/highgui/ios.h>
#import <CoreMotion/CoreMotion.h>
#import  <opencv2/highgui/highgui.hpp>
#import  "opencv2/imgproc/imgproc.hpp"
#include "Math.h"
#import "opencv2/nonfree/nonfree.hpp"

#import  <iostream>
#import  <stdio.h>
#import "opencv2/core/core.hpp"
#import "opencv2/features2d/features2d.hpp"
#import "opencv2/highgui/highgui.hpp"
#import "opencv2/calib3d/calib3d.hpp"

using namespace cv;
using  namespace  std;


@interface ViewController : UIViewController <UIAccelerometerDelegate>
{
    CascadeClassifier faceCascade;
    CascadeClassifier faceCascade_1;
    float px;
    float py;
    float pz;
    
    int numSteps;
    BOOL isChange;
    BOOL isSleeping;
}

@property (weak, nonatomic) IBOutlet UIImageView *cameraView;
@property (strong, nonatomic) NSMutableData *dataResponse;


- (IBAction)box:(id)sender;

- (IBAction)pump:(id)sender;

- (IBAction)beer:(id)sender;

- (IBAction)toothpaste:(id)sender;

- (IBAction)cup:(id)sender;

- (IBAction)stop:(id)sender;

- (IBAction)Load:(id)sender;
- (IBAction)go:(id)sender;
- (IBAction)save:(id)sender;


@end

