//
//  ViewController.m
//  Webcam
//
//  Created by ghm on 16/10/5.
//  Copyright © 2016年 ghm. All rights reserved.
//

// ViewController.h


//  ViewController.m
#import "ViewController.h"
#include <vector>
#include <queue>

NSString* const faceCascadeFilename = @"cascade_toothpaste_13"; //15 good box_055_20
NSString* const faceCascadeFilename_1 = @"cascade_toothpaste_13";
NSString* const faceCascadeFilename_2 = @"cascade_toothpaste_13";
NSString* const faceCascadeFilename_3 = @"cascade_toothpaste_13";
NSString* const faceCascadeFilename_4 = @"cascade_box_24";
const int HaarOptions = CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH;

CGFloat width_x=1.57;
CGFloat image_x ;
CGFloat image_y ;
CGFloat image_z=0;
CGFloat joint_1=0.0,joint_2=0.0,joint_3=0.0;
int navigation_end=0,camera_end=0;
int aa_signal=0;
int delay=0;

Mat CompareImage;
Mat CompareImage1;


int j_1[1][1],j_2[1][1];
int object_1[1][2],object_2[1][2],object[2][2],position_s[4][2],position_s1[4][2];
int mark_position_1x[40],mark_position_2x[40],mark_position_3x[40],mark_position_4x[40],mark_position_1y[40],mark_position_2y[40],mark_position_3y[40],mark_position_4y[40];
int object_1x[20][20],object_2x[20][20],object_3x[400],object_4x[400],object_1y[20][20],object_2y[20][20],object_3y[400],object_4y[400],object_goal=0;
float object_1r[20][20],object_2r[400];
vector<float> object_2rr;
int object_position1x=0,object_position1y=0,object_position2x=0,object_position2y=0;
float object_position2r=0;
int nn1,nn2,nn3,nn4,nn5;
int xx_goal=0;
int object_signal=0;


UILabel * Joint1;
UILabel * Joint2;
UILabel * mark_time;
UILabel * object_time;

CGFloat object_poisition[1][2];
int times=0;
int square=40;
int goal=0;
CGFloat x_x=0,y_y=0;

int begin_1=0;
int frame=4;
int nn=0;
float extra=0.0;
int sequence_times=0;
int di=0;
int nei=2;
int object_goal_time=5;

int f_i=0;
float f_1x[5]={0,0,0,0,0},f_1y[5]={0,0,0,0,0},f_2x[5]={0,0,0,0,0},f_2y[5]={0,0,0,0,0};
float f_3x[4]={0,0,0,0},f_3y[4]={0,0,0,0};
float position_s_0x[15],position_s_0y[15],position_s_1x[15],position_s_1y[15],position_s_2x[15],position_s_2y[15],position_s_3x[10],position_s_3y[15];


@interface ViewController ()
@end

@implementation ViewController
@synthesize cameraView;
//@synthesize label;

@synthesize dataResponse;     // buffer for accumulating data


RBPublisher * imagePublisher;
RBPublisher * widthPublisher;
RBPublisher * extraPublisher;
RBPublisher * navigationPublisher;
RBPublisher * releasePublisher;

RBSubscriber * joint1Subscriber;
RBSubscriber * joint2Subscriber;
RBSubscriber * navigationSubscriber;
RBSubscriber * CameraSubscriber;


- (void)viewDidLoad {
    [super viewDidLoad];
    dataResponse = [NSMutableData dataWithCapacity:10];
    
     NSURLRequest *theRequest =
    [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.149:8080/stream?topic=/camera/rgb/image_raw&width=427&height=320"]];
    
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    dataResponse = [[NSMutableData alloc] init];
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"mark_black_1" ofType:@"jpg"];
    UIImage* resImage = [UIImage imageWithContentsOfFile:filePath];
    
    CompareImage = [self cvMatFromUIImage:resImage];
    NSString* filePath1 = [[NSBundle mainBundle] pathForResource:@"mark_black_2" ofType:@"jpg"];
    UIImage* resImage1 = [UIImage imageWithContentsOfFile:filePath1];
    
    CompareImage1 = [self cvMatFromUIImage:resImage1];
    
    position_s[0][0]=0;
    position_s[0][1]=0;
    position_s[1][0]=0;
    position_s[1][1]=0;
    position_s[2][0]=0;
    position_s[2][1]=0;
    position_s[3][0]=0;
    position_s[3][1]=0;
    position_s1[0][0]=0;
    position_s1[0][1]=0;
    position_s1[1][0]=0;
    position_s1[1][1]=0;
    position_s1[2][0]=0;
    position_s1[2][1]=0;
    position_s1[3][0]=0;
    position_s1[3][1]=0;
    object_poisition[0][0]=0;
    object_poisition[0][1]=0;
    
    for(int i=0;i<40;i++)
    {
        mark_position_1x[i]=0;
        mark_position_1y[i]=0;
        mark_position_2x[i]=0;
        mark_position_2y[i]=0;
        mark_position_3x[i]=0;
        mark_position_3y[i]=0;
        mark_position_4x[i]=0;
        mark_position_4y[i]=0;
    }
    
    for(int i=0;i<20;i++)
    {
        for(int j=0;j<20;j++)
        {
            object_1x[i][j]=0;
            object_1y[i][j]=0;
            object_2x[i][j]=0;
            object_2y[i][j]=0;
            object_1r[i][j]=0.0;
        }
    }
    for(int i;i<400;i++)
    {
        object_3x[i]=0;
        object_3y[i]=0;
        object_4x[i]=0;
        object_4y[i]=0;
        object_2r[i]=0.0;
    }
    
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0 / 60];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
    
    px = py = pz = 0;
    numSteps = 0;

}

- (void)viewDidUnload
{
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// UIAccelerometerDelegate method, called when the device accelerates.
-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    float xx = acceleration.x;
    float yy = acceleration.y;
    float zz = acceleration.z;
    
    float dot = (px * xx) + (py * yy) + (pz * zz);
    float a = ABS(sqrt(px * px + py * py + pz * pz));
    float b = ABS(sqrt(xx * xx + yy * yy + zz * zz));
    
    dot /= (a * b);
    
    if (dot <= 0.82) {
        if (!isSleeping) {
            isSleeping = YES;
            [self performSelector:@selector(wakeUp) withObject:nil afterDelay:0.3];
            numSteps += 1;
        }
    }
    if(joint_1<=0.01&&abs(joint_2-1.05)<0.01)
    {
    if(numSteps>5)
    {
        NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeFilename_4 ofType:@"xml"];
        faceCascade.load([faceCascadePath UTF8String]);
        nei=2;
        di=5;
        begin_1=1;
        width_x=1.3;
        extra=4.0;
        object_goal_time=5;
        for(int i=0;i<5;i++)
        {
            f_1x[i]=0;
            f_1y[i]=0;
            f_2x[i]=0;
            f_2y[i]=0;
        }
        for(int i=0;i<4;i++)
        {
            f_3x[i]=0;
            f_3y[i]=0;
            f_3x[i]=0;
            f_3y[i]=0;
        }
        for(int i=0;i<15;i++)
        {
            position_s_0x[i]=0;
            position_s_0y[i]=0;
            position_s_1x[i]=0;
            position_s_1y[i]=0;
            position_s_2x[i]=0;
            position_s_2y[i]=0;
            position_s_3x[i]=0;
            position_s_3y[i]=0;
        }
        f_i=0;
        numSteps=0;
    }
    }
    px = xx; py = yy; pz = zz;
    
}

- (void)wakeUp {
    isSleeping = NO;
}


- (IBAction)connect:(id)sender {
    [[RBManager defaultManager] connect:@"ws://192.168.1.144:9090"];
    joint1Subscriber = [[RBManager defaultManager] addSubscriber:@"/pickup_end/command" responseTarget:self selector:@selector(joint1PoseUpdate:) messageClass:[FloatMessage class]];
    joint2Subscriber = [[RBManager defaultManager] addSubscriber:@"/pose_signal" responseTarget:self selector:@selector(joint2PoseUpdate:) messageClass:[FloatMessage class]];
    navigationSubscriber = [[RBManager defaultManager] addSubscriber:@"/navigation_signal_end" responseTarget:self selector:@selector(navigationUpdate:) messageClass:[IntMessage class]];
    CameraSubscriber = [[RBManager defaultManager] addSubscriber:@"/camera_signal_end" responseTarget:self selector:@selector(cameraUpdate:) messageClass:[IntMessage class]];
   
}

- (IBAction)disconnnect:(id)sender {
     [[RBManager defaultManager] disconnect];
    begin_1=0;
}

-(void)joint1PoseUpdate:(FloatMessage*)message; {
    
    
    joint_1 = [message.data floatValue];
    
    //cout<<"joint_1 "<<joint_1<<endl;
    
    //self.Joint1.text = [NSString stringWithFormat:@"%.5f", [message.data floatValue]];
    
    //printf("1 3");
}

-(void)joint2PoseUpdate:(FloatMessage*)message; {
    
    
    joint_2 = [message.data floatValue];
    
   // cout<<"joint_2 "<<joint_2<<endl;
    
   // self.Joint2.text = [NSString stringWithFormat:@"%.5f",[message.data floatValue]];
   // printf("1 2");
}

-(void)navigationUpdate:(IntMessage*)message; {
    
    navigation_end = [message.data intValue];

}

-(void)cameraUpdate:(IntMessage*)message; {
    
    
    camera_end = [message.data intValue];
    
    cout<<"camera_end "<<camera_end<<endl;
    while(camera_end>0&&aa_signal<1)
    {
        [NSThread sleepForTimeInterval:12];
        NSURLRequest *theRequest =
        [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.149:8080/stream?topic=/camera/rgb/image_raw&width=427&height=320"]];
        
        NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        cout<<"aa_signal "<<aa_signal<<endl;
        aa_signal++;
        //[NSThread sleepForTimeInterval:2];
    }
    if(camera_end<0.1)
    {
        aa_signal=0;
    }
}


- (IBAction)box:(id)sender {
    object_signal=4;//1;
    object_goal_time=5;
    nei=2;
    di=1;
    begin_1=0;
    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeFilename ofType:@"xml"];
    faceCascade.load([faceCascadePath UTF8String]);
     begin_1=1;
    width_x=1.08;
    extra=0.0;
    for(int i=0;i<5;i++)
    {
        f_1x[i]=0;
        f_1y[i]=0;
        f_2x[i]=0;
        f_2y[i]=0;
    }
    for(int i=0;i<4;i++)
    {
        f_3x[i]=0;
        f_3y[i]=0;
        f_3x[i]=0;
        f_3y[i]=0;
    }

    for(int i=0;i<15;i++)
    {
        position_s_0x[i]=0;
        position_s_0y[i]=0;
        position_s_1x[i]=0;
        position_s_1y[i]=0;
        position_s_2x[i]=0;
        position_s_2y[i]=0;
        position_s_3x[i]=0;
        position_s_3y[i]=0;
    }
    f_i=0;
    for(int i=0;i<20;i++)
    {
        for(int j=0;j<20;j++)
        {
            object_1x[i][j]=0;
            object_1y[i][j]=0;
            object_2x[i][j]=0;
            object_2y[i][j]=0;
        }
    }
    object_goal=0;
    nn1=0;
    nn2=0;
    nn3=0;
    nn4=0;
    nn5=0;

}

- (IBAction)pump:(id)sender {
    object_signal=2;
    object_goal_time=5;
    nei=1;
    di=2;
    begin_1=0;
    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeFilename_1 ofType:@"xml"];
    faceCascade.load([faceCascadePath UTF8String]);
    begin_1=1;
    width_x=1.08;
    extra=2.0;
    for(int i=0;i<5;i++)
    {
        f_1x[i]=0;
        f_1y[i]=0;
        f_2x[i]=0;
        f_2y[i]=0;
    }
    for(int i=0;i<4;i++)
    {
        f_3x[i]=0;
        f_3y[i]=0;
        f_3x[i]=0;
        f_3y[i]=0;
    }
    for(int i=0;i<15;i++)
    {
        position_s_0x[i]=0;
        position_s_0y[i]=0;
        position_s_1x[i]=0;
        position_s_1y[i]=0;
        position_s_2x[i]=0;
        position_s_2y[i]=0;
        position_s_3x[i]=0;
        position_s_3y[i]=0;
    }
    f_i=0;
    for(int i=0;i<20;i++)
    {
        for(int j=0;j<20;j++)
        {
            object_1x[i][j]=0;
            object_1y[i][j]=0;
            object_2x[i][j]=0;
            object_2y[i][j]=0;
        }
    }
    object_goal=0;
    nn1=0;
    nn2=0;
    nn3=0;
    nn4=0;
    nn5=0;
}

- (IBAction)beer:(id)sender {
    object_signal=3;
    object_goal_time=5;
    nei=1;
    di=3;
    begin_1=0;
    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeFilename_2 ofType:@"xml"];
    faceCascade.load([faceCascadePath UTF8String]);
    begin_1=1;
    width_x=1.1;
    extra=3.0;
    for(int i=0;i<5;i++)
    {
        f_1x[i]=0;
        f_1y[i]=0;
        f_2x[i]=0;
        f_2y[i]=0;
    }
    for(int i=0;i<4;i++)
    {
        f_3x[i]=0;
        f_3y[i]=0;
        f_3x[i]=0;
        f_3y[i]=0;
    }
    for(int i=0;i<15;i++)
    {
        position_s_0x[i]=0;
        position_s_0y[i]=0;
        position_s_1x[i]=0;
        position_s_1y[i]=0;
        position_s_2x[i]=0;
        position_s_2y[i]=0;
        position_s_3x[i]=0;
        position_s_3y[i]=0;
    }
    f_i=0;
    for(int i=0;i<20;i++)
    {
        for(int j=0;j<20;j++)
        {
            object_1x[i][j]=0;
            object_1y[i][j]=0;
            object_2x[i][j]=0;
            object_2y[i][j]=0;
        }
    }
    object_goal=0;
    nn1=0;
    nn2=0;
    nn3=0;
    nn4=0;
    nn5=0;
}

- (IBAction)toothpaste:(id)sender {
    object_signal=4;
    object_goal_time=5;
    nei=1;
    di=4;
    begin_1=0;
    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeFilename_3 ofType:@"xml"];
    faceCascade.load([faceCascadePath UTF8String]);
    begin_1=1;
    width_x=1.05;
    extra=1.0;
    for(int i=0;i<5;i++)
    {
        f_1x[i]=0;
        f_1y[i]=0;
        f_2x[i]=0;
        f_2y[i]=0;
    }
    for(int i=0;i<4;i++)
    {
        f_3x[i]=0;
        f_3y[i]=0;
        f_3x[i]=0;
        f_3y[i]=0;
    }
    for(int i=0;i<15;i++)
    {
        position_s_0x[i]=0;
        position_s_0y[i]=0;
        position_s_1x[i]=0;
        position_s_1y[i]=0;
        position_s_2x[i]=0;
        position_s_2y[i]=0;
        position_s_3x[i]=0;
        position_s_3y[i]=0;
    }
    f_i=0;
    for(int i=0;i<20;i++)
    {
        for(int j=0;j<20;j++)
        {
            object_1x[i][j]=0;
            object_1y[i][j]=0;
            object_2x[i][j]=0;
            object_2y[i][j]=0;
        }
    }
    object_goal=0;
    nn1=0;
    nn2=0;
    nn3=0;
    nn4=0;
    nn5=0;
}
- (IBAction)cup:(id)sender {
    object_signal=5;
    object_goal_time=5;
    nei=2;
    di=5;
    begin_1=0;
    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeFilename_4 ofType:@"xml"];
    faceCascade.load([faceCascadePath UTF8String]);
    begin_1=1;
    width_x=1.25;
    extra=3.0;
    for(int i=0;i<5;i++)
    {
        f_1x[i]=0;
        f_1y[i]=0;
        f_2x[i]=0;
        f_2y[i]=0;
    }
    for(int i=0;i<4;i++)
    {
        f_3x[i]=0;
        f_3y[i]=0;
        f_3x[i]=0;
        f_3y[i]=0;
    }
    for(int i=0;i<15;i++)
    {
        position_s_0x[i]=0;
        position_s_0y[i]=0;
        position_s_1x[i]=0;
        position_s_1y[i]=0;
        position_s_2x[i]=0;
        position_s_2y[i]=0;
        position_s_3x[i]=0;
        position_s_3y[i]=0;
    }
    f_i=0;
    for(int i=0;i<20;i++)
    {
        for(int j=0;j<20;j++)
        {
            object_1x[i][j]=0;
            object_1y[i][j]=0;
            object_2x[i][j]=0;
            object_2y[i][j]=0;
        }
    }
    object_goal=0;
    nn1=0;
    nn2=0;
    nn3=0;
    nn4=0;
    nn5=0;
}


- (IBAction)stop:(id)sender {
    begin_1=0;
    width_x=1.57;
    numSteps=0;
    extra=0.0;
    for(int i=0;i<5;i++)
    {
        f_1x[i]=0;
        f_1y[i]=0;
        f_2x[i]=0;
        f_2y[i]=0;
    }
    for(int i=0;i<4;i++)
    {
        f_3x[i]=0;
        f_3y[i]=0;
        f_3x[i]=0;
        f_3y[i]=0;
    }
    for(int i=0;i<15;i++)
    {
        position_s_0x[i]=0;
        position_s_0y[i]=0;
        position_s_1x[i]=0;
        position_s_1y[i]=0;
        position_s_2x[i]=0;
        position_s_2y[i]=0;
        position_s_3x[i]=0;
        position_s_3y[i]=0;
    }
    f_i=0;
    for(int i=0;i<20;i++)
    {
        for(int j=0;j<20;j++)
        {
            object_1x[i][j]=0;
            object_1y[i][j]=0;
            object_2x[i][j]=0;
            object_2y[i][j]=0;
        }
    }
    object_goal=0;
    nn1=0;
    nn2=0;
    nn3=0;
    nn4=0;
    nn5=0;
}



- (IBAction)Load:(id)sender {
    int signal=1;
    releasePublisher = [[RBManager defaultManager] addPublisher:@"/down_signal" messageType:@"std_msgs/Int64"];
    releasePublisher.label = @"Release";
    IntMessage * release_signal = [[IntMessage alloc] init];
    release_signal.data = [NSNumber numberWithInt:signal];
    [releasePublisher publish:release_signal];

    
}

- (IBAction)go:(id)sender {
    
    navigationPublisher = [[RBManager defaultManager] addPublisher:@"/navigation_signal_begin" messageType:@"std_msgs/Int64"];
    navigationPublisher.label = @"Navigation";
    IntMessage * begin_signal = [[IntMessage alloc] init];
    begin_signal.data = [NSNumber numberWithInt:object_signal];
    [navigationPublisher publish:begin_signal];
}




- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [dataResponse appendData:data];
}


- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    // If the image is in black and white
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else { // If it's a color image
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{


    @autoreleasepool
    {
        
        //if(navigation_end>0)
        {
        UIImage *imageZ = [UIImage imageWithData:dataResponse];     // creating image
        cv::Mat inputMat = [self cvMatFromUIImage:imageZ];
        
        if(inputMat.rows>0&&begin_1>0&&joint_1<0.01&&joint_2<0.01)
            {
            
                UIImage *imageZ = [UIImage imageWithData:dataResponse];     // creating image
                cv::Mat inputMat = [self cvMatFromUIImage:imageZ];
        //frame=0;
                if(nn>frame)
                {
                    cv::Mat outputMat=[self processImage:inputMat];
        
                    UIImage *finalImage = [self UIImageFromCVMat:outputMat];
        
                    self.cameraView.image = finalImage;
                    nn=0;
                }
                
                nn++;
        //[self textImage];
            }
        }
        
        
    }
    [dataResponse setLength:0];


}

- (cv::Mat)processImage:(cv::Mat &)image;
{
    //self.mark_time.text=[NSString stringWithFormat:@"%.5d", square];
    //self.object_time.text=[NSString stringWithFormat:@"%.5d", goal];
    int ss=0;
    int re=0;
    /*
     double angle = 90;  // or 270
     cv::Size src_sz = image.size();
     cv::Size dst_sz(src_sz.height, src_sz.width);
     
     int len = std::max(image.cols, image.rows);
     Point2f center(len/2., len/2.);
     Mat rot_mat = cv::getRotationMatrix2D(center, angle, 1.0);
     warpAffine(image, image, rot_mat, dst_sz);
     */
    
//    double angle = 0;  // or 270
//    cv::Size src_sz = image.size();
//    cv::Size dst_sz(src_sz.height, src_sz.width);
//    
//    int len = std::max(image.cols, image.rows);
//    Point2f center(len/2., len/2.);
//    Mat rot_mat = cv::getRotationMatrix2D(center, angle, 1.0);
    
    Mat grayscaleFrame,temp1;
    Mat LoadedImage;
    Mat LoadedImage_0;
    cvtColor(image, grayscaleFrame, CV_BGR2GRAY);
    image.copyTo(LoadedImage);
    //cvtColor(image, LoadedImage, CV_BGR2GRAY);
    
//    warpAffine(image, LoadedImage_0, rot_mat, dst_sz);
//    //cvtColor( LoadedImage_0, LoadedImage, CV_BGR2GRAY );
//    cvtColor(LoadedImage_0, grayscaleFrame, CV_BGR2GRAY);
//    //cvtColor(LoadedImage_0, temp1, CV_BGR2HSV);
//    LoadedImage_0.copyTo(LoadedImage);
//    LoadedImage_0.copyTo(temp1);
    
    
//    for(int j=0;j<temp1.rows;j=j+1)
//    {
//        for (int i=0;i<temp1.cols;i=i+1)
//        {
//            Vec3b p1 = temp1.at<Vec3b>(j,i);
//            int a1;
//            float b1,c1;
//            a1=p1[0];
//            b1=p1[1]*1.0;
//            c1=p1[2]*1.0;
//            //cout<<1<<endl;
//            if(a1<100)//toothpaste a1<255&&a1>60
//            {
//                //                        frame.at<Vec3b>(j,i)[0]=255;
//                //                        frame.at<Vec3b>(j,i)[1]=255;
//                //                        frame.at<Vec3b>(j,i)[2]=255;
//                
//                //                cout<<"x1 "<<a1<<endl;
//                //                cout<<"y1 "<<b1<<endl;
//                //                cout<<"z1 "<<c1<<endl;
//            }
//            else
//            {
//                //                        circle(frame, Point(i,j), 5, cvScalarAll(255),-1);
//                grayscaleFrame.at<uchar>(j,i)=255;
//            }
//            
//        }
//    }

    
    //resize(grayscaleFrame, grayscaleFrame, cv::Size(320,240));
    //resize(LoadedImage,LoadedImage, cv::Size(320,240));
    
    float position[1][2];
    position[0][0]=0;
    position[0][1]=0;
    
    object_1[0][0]=0;
    object_1[0][1]=0;
    object_2[0][0]=0;
    object_2[0][1]=0;
    
    object[0][0]=0;
    object[0][1]=0;
    object[1][0]=0;
    object[1][1]=0;
    
    // j_1[0][0]=0;
    // j_2[0][0]=0;
    /*
     Mat grayscaleFrame;
     Mat LoadedImage;
     cvtColor(image, grayscaleFrame, CV_BGR2GRAY);
     cvtColor(image, LoadedImage, CV_BGR2GRAY);
     */
    
    cv::Point Pt1,Pt2;

    if(square>=40)
    {
        frame=1;
        
        //cout<<"square_00000000"<<endl;
        equalizeHist(grayscaleFrame, grayscaleFrame);
        
        std::vector<cv::Rect> faces;
        std::vector<cv::Rect> faces1;

        faceCascade.detectMultiScale(grayscaleFrame, faces, 1.1, nei, HaarOptions, cv::Size(10,10));
        if(faces.size()>0&&object_goal<20)
        {
            for( size_t i = 0; i < faces.size(); i++ )
            {
                cv::Point pt1(faces[i].x + faces[i].width, faces[i].y + faces[i].height);
                cv::Point pt2(faces[i].x, faces[i].y);
                
                cv::rectangle(LoadedImage, pt1, pt2, cvScalar(255, 255 , 255, 0), 1, 8, 0);
                object[0][0]+=faces[i].x;
                object[0][1]+=(faces[i].y + faces[i].height);
                object[1][0]+=(faces[i].x + faces[i].width);
                object[1][1]+=(faces[i].y + faces[i].height);
                int a1=0,a2=0,a3=0;
                float b1=0,b2=0,b3=0,c1=0,c2=0,c3=0;
                int jj=0,ii=0;
                for(jj=0;jj<(faces[i].height);jj++)
                    {
                        for (ii=0;ii<(faces[i].width);ii++)
                            {
                                Point3_<uchar>* p1 = LoadedImage.ptr<Point3_<uchar> >(faces[i].y+jj,faces[i].x+ii);
                                a1=p1->x;
                                a2=p1->y;
                                a3=p1->z;
                                b1+=(a1)*0.5;
                                b2+=(a2)*0.5;
                                b3+=(a3)*0.5;
                                
                            }
                    }

                c1=b1/(faces[i].height*faces[i].width*1.0);
                c2=b2/(faces[i].height*faces[i].width*1.0);
                c3=b3/(faces[i].height*faces[i].width*1.0);
//                cout<<"c1 "<<c1<<endl;
//                cout<<"c2 "<<c2<<endl;
//                cout<<"c3 "<<c3<<endl;
                if(di==1)//box
                {
                if(c1>c2&&c2>c3&&c1>35)
                {
                object_1x[object_goal][i]=faces[i].x;
                object_1y[object_goal][i]=faces[i].y+ faces[i].height/2;
                object_2x[object_goal][i]=faces[i].x+faces[i].width;
                object_2y[object_goal][i]=faces[i].y+faces[i].height/2;
                object_1r[object_goal][i]=atan2(((faces[i].x+faces[i].height/2)-213.5)*3*0.0028, 2.9);
                cv::rectangle(LoadedImage, pt1, pt2,cvScalarAll(255),1);
//                    cout<<"c1 "<<c1<<endl;
//                    cout<<"c2 "<<c2<<endl;
//                    cout<<"c3 "<<c3<<endl;
                     object_goal++;
                }
                }
                else if (di==2)//pump
                {
                    if(c2>=c3)
                    {
                        object_1x[object_goal][i]=faces[i].x;
                        object_1y[object_goal][i]=faces[i].y+ faces[i].height/2;
                        object_2x[object_goal][i]=faces[i].x+faces[i].width;
                        object_2y[object_goal][i]=faces[i].y+faces[i].height/2;
                        object_1r[object_goal][i]=atan2(((faces[i].x+faces[i].height/2)-213.5)*3*0.0028, 2.9);
                        cv::rectangle(LoadedImage, pt1, pt2, cvScalarAll(255),1);
                        cout<<"c1 "<<c1<<endl;
                        cout<<"c2 "<<c2<<endl;
                        cout<<"c3 "<<c3<<endl;
                         object_goal++;
                    }
                }
                else if (di==3)//beer
                {
                    if(c1>c2&&c2<c3)
                    {
                        object_1x[object_goal][i]=faces[i].x;
                        object_1y[object_goal][i]=faces[i].y+ faces[i].height/2;
                        object_2x[object_goal][i]=faces[i].x+faces[i].width;
                        object_2y[object_goal][i]=faces[i].y+faces[i].height/2;
                        object_1r[object_goal][i]=atan2(((faces[i].x+faces[i].height/2)-213.5)*3*0.0028, 2.9);
                        cv::rectangle(LoadedImage, pt1, pt2, cvScalarAll(255),1);
                                                cout<<"c1 "<<c1<<endl;
                                                cout<<"c2 "<<c2<<endl;
                                                cout<<"c3 "<<c3<<endl;

                         object_goal++;
                    }
                }
                else if(di==4)//toothpaste
                {
                    if(c1<c2&&c2<c3)//&&c1>40)
                    {
                        object_1x[object_goal][i]=faces[i].x;
                        object_1y[object_goal][i]=faces[i].y+ faces[i].height/2;
                        object_2x[object_goal][i]=faces[i].x+faces[i].width;
                        object_2y[object_goal][i]=faces[i].y+faces[i].height/2;
                        object_1r[object_goal][i]=atan2(((faces[i].x+faces[i].height/2)-213.5)*3*0.0028, 2.9);
                        cv::rectangle(LoadedImage, pt1, pt2, cvScalarAll(255),1);
//                        cout<<"c1 "<<c1<<endl;
//                        cout<<"c2 "<<c2<<endl;
//                        cout<<"c3 "<<c3<<endl;
                         object_goal++;
                    }
                }
                else if(di==5)//cup
                {
                    if(c3>c2&&c1>c2)//&&c2<c3)//&&c1>40)
                    {
                        object_1x[object_goal][i]=faces[i].x;
                        object_1y[object_goal][i]=faces[i].y+ faces[i].height*2/3;
                        object_2x[object_goal][i]=faces[i].x+faces[i].width;
                        object_2y[object_goal][i]=faces[i].y+faces[i].height*2/3;
                        object_1r[object_goal][i]=atan2(((faces[i].x+faces[i].height/2)-213.5)*3*0.0028, 2.9);
                        cv::rectangle(LoadedImage, pt1, pt2, cvScalarAll(255),1);
//                        cout<<"c1 "<<c1<<endl;
//                        cout<<"c2 "<<c2<<endl;
//                        cout<<"c3 "<<c3<<endl;
                         object_goal++;
                    }
                }
                else
                {
                }

                
            }
//            object_1[0][0]=object[0][0]/faces.size();
//            object_1[0][1]=object[0][1]/faces.size();
//            object_2[0][0]=object[1][0]/faces.size();
//            object_2[0][1]=object[1][1]/faces.size();
//            Pt1.x=object_1[0][0];
//            Pt1.y=object_1[0][1];
//            Pt2.x=object_2[0][0];
//            Pt2.y=object_2[0][1];
            // imshow( window_name,frame );
            //  detectAndDisplay(frame);
            
//            f_1x[f_i]=object[0][0]/faces.size();
//            f_1y[f_i]=object[0][1]/faces.size();
//            f_2x[f_i]=object[1][0]/faces.size();
//            f_2y[f_i]=object[1][1]/faces.size();
//            f_i++;
        }
        
        //cout<<"square"<<object_goal<<endl;
        if(object_goal>=object_goal_time)
        {
           // cout<<"1"<<endl;
            for(int i=0;i<20;i++)
            {
                for(int j=0;j<20;j++)
                {
                    if(object_1x[i][j]>0)
                    {
                        object_3x[nn1]=object_1x[i][j];
                        nn1++;
                    }
                    if(object_1y[i][j]>0)
                    {
                        object_3y[nn2]=object_1y[i][j];
                        nn2++;
                    }
                    if(object_2x[i][j]>0)
                    {
                        object_4x[nn3]=object_2x[i][j];
                        nn3++;
                    }
                    if(object_2y[i][j]>0)
                    {
                        object_4y[nn4]=object_2y[i][j];
                        nn4++;
                    }
                    if(object_1r[i][j]!=0)
                    {
                        object_2r[nn5]=object_1r[i][j];
                        float a_a=0;
                        a_a=object_1r[i][j];
                        object_2rr.push_back(a_a);
                        
                        nn5++;
                    }
                }
            }
            if(nn1>0||nn2>0||nn3>0||nn4>0||nn5>0)
            {
               // cout<<"2"<<endl;
                object_position1x=sequence(object_3x, nn1);
                object_position1y=sequence(object_3y, nn2);
                object_position2x=sequence(object_4x, nn3);
                object_position2y=sequence(object_4y, nn4);
                int r_size;
                if(object_2rr.size()>1)
                {
                     r_size=int(object_2rr.size()/2);
                }
                else
                {
                    r_size=0;
                }
                
                sort(object_2rr.begin(), object_2rr.end(), compare_1);
                
                //object_position2r=sequence_1(object_2r, nn5);
               // cout<<"3333"<<endl;
                object_1[0][0]=object_position1x;
                object_1[0][1]=object_position1y;
                object_2[0][0]=object_position2x;
                object_2[0][1]=object_position2y;
                Pt1.x=object_1[0][0];
                Pt1.y=object_1[0][1];
                Pt2.x=object_2[0][0];
                Pt2.y=object_2[0][1];
                //image_z=object_position2r;
                image_z=object_2rr[r_size];
            
                
                for(int i=0;i<20;i++)
                {
                    for(int j=0;j<20;j++)
                    {
                        object_1x[i][j]=0;
                        object_1y[i][j]=0;
                        object_2x[i][j]=0;
                        object_2y[i][j]=0;
                    }
                }
                object_goal=0;
                nn1=0;
                nn2=0;
                nn3=0;
                nn4=0;
                nn5=0;
                object_2rr.clear();
                re=1;

            }
            
        }

//        if(f_i>5)
//        {
//            cout<<"00_00"<<endl;
//        object_1[0][0]=EvaluateMedian(f_1x, f_i);
//        object_1[0][1]=EvaluateMedian(f_1y, f_i);
//        object_2[0][0]=EvaluateMedian(f_2x, f_i);
//        object_2[0][1]=EvaluateMedian(f_2y, f_i);
//        Pt1.x=object_1[0][0];
//        Pt1.y=object_1[0][1];
//        Pt2.x=object_2[0][0];
//        Pt2.y=object_2[0][1];
//            for(int i=0;i<5;i++)
//            {
//                f_1x[i]=0;
//                f_1y[i]=0;
//                f_2x[i]=0;
//                f_2y[i]=0;
//            }
//            f_i=0;
//        re=1;
//        }
    }
    
    //cvtColor( LoadedImage, LoadedImage, CV_BGR2GRAY );
   //  /*
    
    
    imagePublisher = [[RBManager defaultManager] addPublisher:@"/image_pose" messageType:@"geometry_msgs/Point"];
    imagePublisher.label = @"Image_pose";
    widthPublisher = [[RBManager defaultManager] addPublisher:@"/width" messageType:@"std_msgs/Float64"];
    widthPublisher.label = @"Width";
    
    extraPublisher = [[RBManager defaultManager] addPublisher:@"/extra" messageType:@"std_msgs/Float64"];
    extraPublisher.label = @"Extra";
    
    FloatMessage * width = [[FloatMessage alloc] init];
    width.data = [NSNumber numberWithFloat:width_x];
    
    FloatMessage * extra_distance = [[FloatMessage alloc] init];
    extra_distance.data = [NSNumber numberWithFloat:extra];
    
    circle(LoadedImage, cv::Point(213,160), 5, cvScalarAll(255));
    
    if((Pt1.x+Pt2.x)/2>0&&(Pt1.y+Pt2.y)/2>0)
    {
    
        image_x=(Pt1.x+Pt2.x)/2;
        image_y=(Pt1.y+Pt2.y)/2;
        cout<<"x "<<image_x<<endl;
        cout<<"y "<<image_y<<endl;
        cout<<"z "<<image_z*180/3.141592654<<endl;
    
        PointMessage * imagePose = [[PointMessage alloc] init];
        imagePose.x = [NSNumber numberWithFloat:image_x];
        imagePose.y = [NSNumber numberWithFloat:image_y];
        if(image_z<=0)
        {
            image_z=image_z+0.03;
        }
        else
        {
            image_z=image_z+0.05;
        }
        imagePose.z = [NSNumber numberWithFloat:image_z];
        if(delay>1)
        {
            delay=0;
            
            for(int i=0;i<2;i++)
            {
            
        [imagePublisher publish:imagePose];
        //[NSThread sleepForTimeInterval:2];
        
        
        [widthPublisher publish:width];
        [extraPublisher publish:extra_distance];
                 [NSThread sleepForTimeInterval:0.3];
            }
        }
        delay++;
    }
    
    

    cv::rectangle(LoadedImage, Pt1, Pt2, cvScalarAll(255),5);
    cv::resize(LoadedImage, LoadedImage, cv::Size(320,240));
    //cvtColor(LoadedImage, LoadedImage, CV_GRAY2BGR);
    LoadedImage.copyTo(image);
    
    return (cv::Mat &)image;
    
    
}



int Otsu(Mat src)
{
    int height = src.cols;
    int width = src.rows;
    //cout<<"height "<<src.step+src.channels()<<endl;
    
    //histogram
    float histogram[256] = { 0 };
    for (int i = 0; i < height; i++)
    {
        unsigned char* p = (unsigned char*)src.data + src.step* i;
        for (int j = 0; j < width; j++)
        {
            histogram[*p++]++;
        }
    }
    //normalize histogram
    int size = height * width;
    for (int i = 0; i < 256; i++)
    {
        histogram[i] = histogram[i] / size;
    }
    
    //average pixel value
    float avgValue = 0;
    for (int i = 0; i < 256; i++)
    {
        avgValue += i * histogram[i];  //整幅图像的平均灰度
    }
    
    int threshold=0;
    float maxVariance = 0;
    float w = 0, u = 0;
    for (int i = 0; i < 256; i++)
    {
        w += histogram[i];
        u += i * histogram[i];
        
        float t = avgValue * w - u;
        float variance = t * t / (w * (1 - w));
        if (variance > maxVariance)
        {
            maxVariance = variance;
            threshold = i;
        }
    }
    
    return threshold;
}

int QuickSortOnce(float a[], int low, int high)
{
  
    float pivot = a[low];
    int i = low, j = high;
    
    while (i < j)
    {
 
        while (a[j] >= pivot && i < j)
        {
            j--;
        }
        

        a[i] = a[j];
        

        while (a[i] <= pivot && i < j)
        {
            i++;
        }
        

        a[j] = a[i];
    }
    

    a[i] = pivot;
    return i;
}

void QuickSort(float a[], int low, int high)
{
    if (low >= high)
    {
        return;
    }
    
    int pivot = QuickSortOnce(a, low, high);
    

    QuickSort(a, low, pivot - 1);
    

    QuickSort(a, pivot + 1, high);
}

float EvaluateMedian(float a[], int n)
{
    QuickSort(a, 0, n - 1);
    
    if(n % 2 !=0)
    {
        return a[n / 2];
    }
    else
    {
        
        return (a[n / 2] + a[n / 2 - 1]) / 2;
    }
}

int sequence(int a[],int n)
{
    
    map<int,int> m;
    for(int i = 0;i<n;i++){
//        int num;
//        a[i]=num;
        
        m[a[i]]++;
    }
    
    map<int, int>::const_iterator cit = m.begin();
    int targetNum = cit->first;
    int mostFrequency = cit->second;
    for(++cit; cit!=m.end(); ++cit){
        if(cit->second > mostFrequency){
            targetNum = cit->first;
            mostFrequency = cit->second;
        }
    }
    
    cout<<"most times number： "<<targetNum<<endl
    <<"times： "<<mostFrequency<<endl;
    
    return targetNum;
}
float sequence_1(float a[],int n)
{
    
    map<float,float> m;
    for(int i = 0;i<n;i++){
        //        int num;
        //        a[i]=num;
        
        m[a[i]]++;
    }
    
    map<float, float>::const_iterator cit = m.begin();
    float targetNum = cit->first;
    float mostFrequency = cit->second;
    cout<<"targetNum "<<targetNum<<endl;
    cout<<"mostFrequency "<<mostFrequency<<endl;
    
    for(++cit; cit!=m.end(); ++cit){
        
        if(cit->second > mostFrequency){
            targetNum = cit->first;
            mostFrequency = cit->second;
        }
    }
    
    cout<<"most times number： "<<targetNum<<endl
    <<"times： "<<mostFrequency<<endl;
    
    return targetNum;
}

bool compare_1(float a,float b)
{
    return (a<b);
}



-(NSString*) saveFilePath
{
    NSString* path = [NSString stringWithFormat:@"%@%@",
                      [[NSBundle mainBundle] resourcePath],
                      @"myfilename.plist"];
    return path;
}




- (void)didReceiveMemoryWarning {[super didReceiveMemoryWarning];}




@end
