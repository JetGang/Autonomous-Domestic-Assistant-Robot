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

NSString* const faceCascadeFilename = @"cascade_box_15";
NSString* const faceCascadeFilename_1 = @"cascade_cup_23";
const int HaarOptions = CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH;
CGFloat x ;
CGFloat y ;
CGFloat theta;
CGFloat joint_1=0,joint_2=1.05,joint_3,joint_4;

Mat CompareImage;
Mat CompareImage1;

int j_1[1][1],j_2[1][1];
int object_1[1][2],object_2[1][2],object[2][2];

UILabel * Joint1;
UILabel * Joint2;

CGFloat object_poisition[1][2];
int times=0;
CGFloat x_x=0,y_y=0;


@interface ViewController ()
@end

@implementation ViewController
@synthesize cameraView;
//@synthesize label;

@synthesize dataResponse;     // buffer for accumulating data

RBPublisher * shoulderPublisher;
RBSubscriber * joint1Subscriber;
RBSubscriber * joint2Subscriber;


- (void)viewDidLoad {
    [super viewDidLoad];
    dataResponse = [NSMutableData dataWithCapacity:100];
    
    NSURLRequest *theRequest =
    [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.209:8090/?action=stream"]];
    
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    dataResponse = [[NSMutableData alloc] init];
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"mark_black_1" ofType:@"jpg"];
    UIImage* resImage = [UIImage imageWithContentsOfFile:filePath];
    
    CompareImage = [self cvMatFromUIImage:resImage];
    NSString* filePath1 = [[NSBundle mainBundle] pathForResource:@"mark_black_2" ofType:@"jpg"];
    UIImage* resImage1 = [UIImage imageWithContentsOfFile:filePath1];
    
    CompareImage1 = [self cvMatFromUIImage:resImage1];
    
}

- (IBAction)connect:(id)sender {
    [[RBManager defaultManager] connect:@"ws://192.168.1.209:9090"];
    joint1Subscriber = [[RBManager defaultManager] addSubscriber:@"/pickup_end/command" responseTarget:self selector:@selector(joint1PoseUpdate:) messageClass:[FloatMessage class]];
    joint2Subscriber = [[RBManager defaultManager] addSubscriber:@"/arm_shoulder_lift_joint/command" responseTarget:self selector:@selector(joint2PoseUpdate:) messageClass:[FloatMessage class]];
}

- (IBAction)disconnnect:(id)sender {
     [[RBManager defaultManager] disconnect];
}

-(void)joint1PoseUpdate:(FloatMessage*)message; {
    
    
    joint_1 = [message.data floatValue];
    
    cout<<"joint_1 "<<joint_1<<endl;
    
    self.Joint1.text = [NSString stringWithFormat:@"%.5f", [message.data floatValue]];
    
    printf("1 3");
}

-(void)joint2PoseUpdate:(FloatMessage*)message; {
    
    
    joint_2 = [message.data floatValue];
    
    cout<<"joint_2 "<<joint_2<<endl;
    
    self.Joint2.text = [NSString stringWithFormat:@"%.5f",[message.data floatValue]];
    printf("1 2");
}

- (IBAction)box:(id)sender {

}

- (IBAction)cup:(id)sender {
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

    NSString* faceCascadePath = [[NSBundle mainBundle] pathForResource:faceCascadeFilename ofType:@"xml"];
    faceCascade.load([faceCascadePath UTF8String]);
    
    @autoreleasepool
    {
        UIImage *imageZ = [UIImage imageWithData:dataResponse];     // creating image
        cv::Mat inputMat = [self cvMatFromUIImage:imageZ];
        if(inputMat.rows>0)
        {
        cv::Mat outputMat=[self processImage:inputMat];
        
        UIImage *finalImage = [self UIImageFromCVMat:outputMat];
            
        self.cameraView.image = finalImage;
        }
        //cv::rectangle(inputMat, cv::Point(100,100), cv::Point(150,150), cvScalar(255),10);
        /*
         Mat grayscaleFrame;
         Mat LoadedImage;
         cvtColor(inputMat, grayscaleFrame, CV_BGR2GRAY);
         cvtColor(inputMat, LoadedImage, CV_BGR2GRAY);
         cv::Point Pt1,Pt2;
         
         
         equalizeHist(grayscaleFrame, grayscaleFrame);
         
         std::vector<cv::Rect> faces;
         std::vector<cv::Rect> faces1;
         faceCascade.detectMultiScale(grayscaleFrame, faces, 1.1, 2, HaarOptions, cv::Size(5,5));
         if(faces.size()>0){
         for( size_t i = 0; i < faces.size(); i++ )
         {
         cv::Point pt1(faces[i].x + faces[i].width, faces[i].y + faces[i].height);
         cv::Point pt2(faces[i].x, faces[i].y);
         
         cv::rectangle(inputMat, pt1, pt2, cvScalar(255, 255 , 255, 0), 1, 8, 0);
         
         
         }
         
         // imshow( window_name,frame );
         //  detectAndDisplay(frame);
         }
         */
        
        //UIImage *finalImage = [self UIImageFromCVMat:inputMat];
        
        //self.cameraView.image = finalImage;       // image to UIImageView
        
    }
    [dataResponse setLength:0];
}

- (cv::Mat)processImage:(cv::Mat &)image;
{
    /*
     double angle = 90;  // or 270
     cv::Size src_sz = image.size();
     cv::Size dst_sz(src_sz.height, src_sz.width);
     
     int len = std::max(image.cols, image.rows);
     Point2f center(len/2., len/2.);
     Mat rot_mat = cv::getRotationMatrix2D(center, angle, 1.0);
     warpAffine(image, image, rot_mat, dst_sz);
     */
    
    double angle = 90;  // or 270
    cv::Size src_sz = image.size();
    cv::Size dst_sz(src_sz.height, src_sz.width);
    
    int len = std::max(image.cols, image.rows);
    Point2f center(len/2., len/2.);
    Mat rot_mat = cv::getRotationMatrix2D(center, angle, 1.0);
    
    Mat grayscaleFrame;
    Mat LoadedImage;
    Mat LoadedImage_0;
    //cvtColor(image, grayscaleFrame, CV_BGR2GRAY);
    //cvtColor(image, LoadedImage, CV_BGR2GRAY);
    
    warpAffine(image, LoadedImage_0, rot_mat, dst_sz);
    cvtColor( LoadedImage_0, LoadedImage, CV_BGR2GRAY );
    cvtColor(LoadedImage_0, grayscaleFrame, CV_BGR2GRAY);
    
    
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
    
    
    equalizeHist(grayscaleFrame, grayscaleFrame);
    
    std::vector<cv::Rect> faces;
    std::vector<cv::Rect> faces1;
    faceCascade.detectMultiScale(grayscaleFrame, faces, 1.1, 2, HaarOptions, cv::Size(25,25));
    if(faces.size()>0){
        for( size_t i = 0; i < faces.size(); i++ )
        {
            cv::Point pt1(faces[i].x + faces[i].width, faces[i].y + faces[i].height);
            cv::Point pt2(faces[i].x, faces[i].y);
            
            cv::rectangle(grayscaleFrame, pt1, pt2, cvScalar(255, 255 , 255, 0), 1, 8, 0);
            cout<<"face11 "<<pt1.x-faces[i].width<<endl;
            cout<<"face12 "<<pt1.y<<endl;
            cout<<"face21 "<<pt1.x<<endl;
            cout<<"face22 "<<pt1.y<<endl;
            object[0][0]+=faces[i].x;
            object[0][1]+=(faces[i].y + faces[i].height);
            object[1][0]+=(faces[i].x + faces[i].width);
            object[1][1]+=(faces[i].y + faces[i].height);
            
        }
        object_1[0][0]=object[0][0]/faces.size();
        object_1[0][1]=object[0][1]/faces.size();
        object_2[0][0]=object[1][0]/faces.size();
        object_2[0][1]=object[1][1]/faces.size();
        Pt1.x=object_1[0][0];
        Pt1.y=object_1[0][1];
        Pt2.x=object_2[0][0];
        Pt2.y=object_2[0][1];
        // imshow( window_name,frame );
        //  detectAndDisplay(frame);
    }
    
    
    
    // /*
     
     //  if(Pt1.x>0)
     //  {
     int position1[1][2],position2[1][2],position_square2[4][2];
     position1[0][0]=0;
     position1[0][1]=0;
     int position_square_1[1][2],position_square_2[1][2],position_square_3[1][2],position_square_4[1][2];
     position1[0][0]=0;
     position1[0][1]=0;
     position_square_1[0][0]=0;
     position_square_1[0][1]=0;
     position_square_2[0][0]=0;
     position_square_2[0][1]=0;
     position_square_3[0][0]=0;
     position_square_3[0][1]=0;
     position_square_4[0][0]=0;
     position_square_4[0][1]=0;
   
     
     resize(CompareImage, CompareImage, cv::Size(100,100));
     resize(CompareImage1, CompareImage1, cv::Size(80,80));
    
     resize(LoadedImage, LoadedImage, cv::Size(900,1200));
     
    
     Match(CompareImage, LoadedImage, position1,2050,j_1);
    
    
     if(j_1[0][0]>0)
     {
     
     resize(LoadedImage, LoadedImage, cv::Size(480,640));
     if(position1[0][0]<300 && position1[0][1]<400&&position1[0][0]>0 && position1[0][1]>0)
     {
     cout<<"01"<<endl;
     cv::Rect Rec(position1[0][0]/3,position1[0][1]/3.6, 150, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     //cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 100);
     //rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     if ((position2[0][0]/3+100)<150 && (position2[0][1]/3.6+100)<150 )
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/3+100)>150 && (position2[0][1]/3.6+100)<150)
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 150-position2[0][0]/3, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/3+100)<150 && (position2[0][1]/3.6+100)>150)
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 150-position2[0][1]/3.6);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 150-position2[0][0]/3, 150-position2[0][1]/3.6);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/3+position1[0][0]/3;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/3+position1[0][0]/3;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/3+position1[0][0]/3;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/3+position1[0][0]/3;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     
     cv::Rect WhereRec(position1[0][0]/3,position1[0][1]/3.6, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/3&&position_square2[0][0]<position1[0][0]/3+150&&position_square2[0][1]>position1[0][1]/3.6&&position_square2[0][1]<position1[0][1]/3.6+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     //  [self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     
     }
     }
     
     }
     else if(position1[0][0]<600 && 300<position1[0][0] && position1[0][1]<400&&position1[0][1]>0)
     {
     cout<<"02"<<endl;
     cv::Rect Rec(position1[0][0]/2.5,position1[0][1]/3.6, 150, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     // cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 100);
     // rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     if ((position2[0][0]/3+100)<150 && (position2[0][1]/3.6+100)<150 )
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/3+100)>150 && (position2[0][1]/3.6+100)<150)
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 150-position2[0][0]/3, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/3+100)<150 && (position2[0][1]/3.6+100)>150)
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 150-position2[0][1]/3.6);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 150-position2[0][0]/3, 150-position2[0][1]/3.6);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/3+position1[0][0]/2.5;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/3+position1[0][0]/2.5;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/3+position1[0][0]/2.5;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/3+position1[0][0]/2.5;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     
     
     
     cv::Rect WhereRec(position1[0][0]/2.5,position1[0][1]/3.6, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     // namedWindow("Step 4  Final result", WINDOW_AUTOSIZE);
     // imshow("Step 4 Final result", LoadedImage);
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/2.5&&position_square2[0][0]<position1[0][0]/2.5+150&&position_square2[0][1]>position1[0][1]/3.6&&position_square2[0][1]<position1[0][1]/3.6+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     //  [self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     
     }
     }
     }
     else if(600<position1[0][0] && position1[0][1]<400&&position1[0][0]<900 && position1[0][1]>0)
     {
     cout<<"03"<<endl;
     cv::Rect Rec(position1[0][0]/2.2,position1[0][1]/3.6, 150, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     // Show what rectangle
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     // cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 100);
     // rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     if ((position2[0][0]/3+100)<150 && (position2[0][1]/3.6+100)<150 )
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/3+100)>150 && (position2[0][1]/3.6+100)<150)
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 150-position2[0][0]/3, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/3+100)<150 && (position2[0][1]/3.6+100)>150)
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 100, 150-position2[0][1]/3.6);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cv::Rect Small(position2[0][0]/3,position2[0][1]/3.6, 150-position2[0][0]/3, 150-position2[0][1]/3.6);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/3+position1[0][0]/2.2;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/3+position1[0][0]/2.2;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/3+position1[0][0]/2.2;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/3+position1[0][0]/2.2;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/3.6+position1[0][1]/3.6;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     
     
     
     cv::Rect WhereRec(position1[0][0]/2.2,position1[0][1]/3.6, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/2.2&&position_square2[0][0]<position1[0][0]/2.2+150&&position_square2[0][1]>position1[0][1]/3.6&&position_square2[0][1]<position1[0][1]/3.6+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     //[self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     
     }
     }
     }
     else if(position1[0][0]<300 && 400<position1[0][1] && position1[0][1]<800)
     {
     cout<<"04"<<endl;
     cv::Rect Rec(position1[0][0]/4,position1[0][1]/2.5, 150, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     //cv::Rect Small(position2[0][0]/2,position2[0][1]/3.6, 100, 100);
     //rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     if ((position2[0][0]/2+100)<150 && (position2[0][1]/3.6+100)<150 )
     {
     cv::Rect Small(position2[0][0]/2,position2[0][1]/3.6, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/2+100)>150 && (position2[0][1]/3.6+100)<150)
     {
     cv::Rect Small(position2[0][0]/2,position2[0][1]/3.6, 150-position2[0][0]/2, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/2+100)<150 && (position2[0][1]/3.6+100)>150)
     {
     cv::Rect Small(position2[0][0]/2,position2[0][1]/3.6, 100, 150-position2[0][1]/3.6);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cv::Rect Small(position2[0][0]/2,position2[0][1]/3.6, 150-position2[0][0]/2, 150-position2[0][1]/3.6);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/4+position1[0][0]/4;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/3.6+position1[0][1]/2.5;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/4+position1[0][0]/4;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/3.6+position1[0][1]/2.5;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/4+position1[0][0]/4;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/3.6+position1[0][1]/2.5;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/4+position1[0][0]/4;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/3.6+position1[0][1]/2.5;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     
     
     
     cv::Rect WhereRec(position1[0][0]/4,position1[0][1]/2.5, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/4&&position_square2[0][0]<position1[0][0]/4+150&&position_square2[0][1]>position1[0][1]/2.5&&position_square2[0][1]<position1[0][1]/2.5+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     // [self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     
     }
     }
     
     }
     else if(300<position1[0][0] && position1[0][0]<600 && 400<position1[0][1] && position1[0][1]<800)
     {
     cout<<"05"<<endl;
     cv::Rect Rec(position1[0][0]/2.6,position1[0][1]/2.6, 150, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     //cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 100, 100);
     //rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     if ((position2[0][0]/2.7+100)<150 && (position2[0][1]/2.7+100)<150 )
     {
     cout<<" 51 "<<endl;
         
     cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 100, 100);
      
     cout<<" 511 "<<endl;
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     cout<<" 512 "<<endl;
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     cout<<" 513 "<<endl;
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     cout<<" 514 "<<endl; 
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/2.7+100)>150 && (position2[0][1]/2.7+100)<150)
     {
     cout<<" 52 "<<endl;
     cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 150-position2[0][0]/2.7, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/2.7+100)<150 && (position2[0][1]/2.7+100)>150)
     {
     cout<<" 53 "<<endl;
     cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 100, 150-position2[0][1]/2.7);
         
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cout<<" 54 "<<endl;
     cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 150-position2[0][0]/2.7, 150-position2[0][1]/2.7);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/2.7+position1[0][0]/2.6;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/2.7+position1[0][1]/2.6;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/2.7+position1[0][0]/2.6;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/2.7+position1[0][1]/2.6;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/2.7+position1[0][0]/2.6;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/2.7+position1[0][1]/2.6;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/2.7+position1[0][0]/2.6;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/2.7+position1[0][1]/2.6;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     
     cv::Rect WhereRec(position1[0][0]/2.6,position1[0][1]/2.6, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/2.6&&position_square2[0][0]<position1[0][0]/2.6+150&&position_square2[0][1]>position1[0][1]/2.6&&position_square2[0][1]<position1[0][1]/2.6+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     // [self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     
     }
     }
     }
     else if(600<position1[0][0] && 400<position1[0][1] && position1[0][1]<800)
     {
     cout<<"06"<<endl;
     cv::Rect Rec(position1[0][0]/2.2,position1[0][1]/2.6, 480-position1[0][0]/2.2, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     //cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 480-position1[0][0]/2.2-position2[0][0]/2.7, 100);
     //rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     
     if ((position2[0][0]/2.7+100)<480-position1[0][0]/2.2 && (position2[0][1]/2.7+100)<150 )
     {
     cout<<" 61 "<<endl;
     cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/2.7+100)>480-position1[0][0]/2.2 && (position2[0][1]/2.7+100)<150)
     {
     cout<<" 62 "<<endl;
     cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 480-position1[0][0]/2.2-position2[0][0]/2.7, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/2.7+100)<480-position1[0][0]/2.2 && (position2[0][1]/2.7+100)>150)
     {
     cout<<" 63 "<<endl;
     cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 100, 150-position2[0][1]/2.7);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cout<<" 64 "<<endl;
     cv::Rect Small(position2[0][0]/2.7,position2[0][1]/2.7, 480-position1[0][0]/2.2-position2[0][0]/2.7, 150-position2[0][1]/2.7);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/2.7+position1[0][0]/2.2;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/2.7+position1[0][1]/2.6;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/2.7+position1[0][0]/2.2;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/2.7+position1[0][1]/2.6;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/2.7+position1[0][0]/2.2;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/2.7+position1[0][1]/2.6;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/2.7+position1[0][0]/2.2;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/2.7+position1[0][1]/2.6;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     
     cv::Rect WhereRec(position1[0][0]/2.2,position1[0][1]/2.6, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/2.2&&position_square2[0][0]<position1[0][0]/2.2+150&&position_square2[0][1]>position1[0][1]/2.6&&position_square2[0][1]<position1[0][1]/2.6+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     //[self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     
     }
     }
     
     }
     else if(position1[0][0]<300 && 800<position1[0][1])
     {
     if(position1[0][1]+150<=1200)
     {
     cout<<"07"<<endl;
     cv::Rect Rec(position1[0][0]/3.5,position1[0][1]/2.2, 150, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     // cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 100, 100);
     // rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     if ((position2[0][0]/3.5+100)<150 && (position2[0][1]/2.5+100)<150 )
     {
     cout<<" 71 "<<endl;
     cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/3.5+100)>150 && (position2[0][1]/2.5+100)<150)
     {
     cout<<" 72 "<<endl;
     cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 150-position2[0][0]/3.5, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/3.5+100)<150 && (position2[0][1]/2.5+100)>150)
     {
     cout<<" 73 "<<endl;
     cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 100, 150-position2[0][1]/2.5);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cout<<" 74 "<<endl;
     cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 150-position2[0][0]/3.5, 150-position2[0][1]/2.5);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/3.5+position1[0][0]/3.5;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/2.5+position1[0][1]/2.2;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/3.5+position1[0][0]/3.5;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/2.5+position1[0][1]/2.2;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/3.5+position1[0][0]/3.5;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/2.5+position1[0][1]/2.2;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/3.5+position1[0][0]/3.5;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/2.5+position1[0][1]/2.2;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     cv::Rect WhereRec(position1[0][0]/3.5,position1[0][1]/2.2, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/3.5&&position_square2[0][0]<position1[0][0]/3.5+150&&position_square2[0][1]>position1[0][1]/2.2&&position_square2[0][1]<position1[0][1]/2.2+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times "<<times<<endl;
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     //[self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     
     }
     }
     }
     
     else
     {
     cout<<"07_1"<<endl;
     cv::Rect Rec(position1[0][0]/3.5,position1[0][1]/2.2, 150, 1200-position1[0][1]);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     // cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 100, 100);
     // rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     if ((position2[0][0]/3.5+100)<150 && (position2[0][1]/2.5+100)<(1200-position1[0][1]))
     {
     cout<<" 7_1 "<<endl;
     cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" _1 "<<endl;
     }
     else if((position2[0][0]/3.5+100)>150 && (position2[0][1]/2.5+100)<(1200-position1[0][1]))
     {
     cout<<" 7_2 "<<endl;
     cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 150-position2[0][0]/3.5, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" _2 "<<endl;
     }
     else if((position2[0][0]/3.5+100)<150 && (position2[0][1]/2.5+100)>(1200-position1[0][1]))
     {
     cout<<" 7_3 "<<endl;
     cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 100, 1200-position1[0][1]-position2[0][1]/2.5);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" _3 "<<endl;
     }
     else
     {
     cout<<" 7_4 "<<endl;
     cv::Rect Small(position2[0][0]/3.5,position2[0][1]/2.5, 150-position2[0][0]/3.5, 1200-position1[0][1]-position2[0][1]/2.5);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" _4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/3.5+position1[0][0]/3.5;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/2.5+position1[0][1]/2.2;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/3.5+position1[0][0]/3.5;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/2.5+position1[0][1]/2.2;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/3.5+position1[0][0]/3.5;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/2.5+position1[0][1]/2.2;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/3.5+position1[0][0]/3.5;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/2.5+position1[0][1]/2.2;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     
     cv::Rect WhereRec(position1[0][0]/3.5,position1[0][1]/2.2, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/3.5&&position_square2[0][0]<position1[0][0]/3.5+150&&position_square2[0][1]>position1[0][1]/2.2&&position_square2[0][1]<position1[0][1]/2.2+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     //   [self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     
     }
     }
     }
     
     }
     else if(300<position1[0][0] && position1[0][0]<600 && 800<position1[0][1])
     {
     cout<<"08"<<endl;
     cv::Rect Rec(position1[0][0]/2.5,position1[0][1]/2.2, 150, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     //cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 100, 100);
     //rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     if ((position2[0][0]/2.8+100)<150 && (position2[0][1]/2.2+100)<150 )
     {
     cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/2.8+100)>150 && (position2[0][1]/2.2+100)<150)
     {
     cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 150-position2[0][0]/2.8, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/2.8+100)<150 && (position2[0][1]/2.2+100)>150)
     {
     cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 100, 150-position2[0][1]/2.2);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 150-position2[0][0]/2.8, 150-position2[0][1]/2.2);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/2.8+position1[0][0]/2.5;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/2.2+position1[0][1]/2.2;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/2.8+position1[0][0]/2.5;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/2.2+position1[0][1]/2.2;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/2.8+position1[0][0]/2.5;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/2.2+position1[0][1]/2.2;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/2.8+position1[0][0]/2.5;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/2.2+position1[0][1]/2.2;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     cv::Rect WhereRec(position1[0][0]/2.5,position1[0][1]/2.2, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/2.5&&position_square2[0][0]<position1[0][0]/2.5+150&&position_square2[0][1]>position1[0][1]/2.2&&position_square2[0][1]<position1[0][1]/2.2+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     // [self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
    
     }
     }
     }
     else
     {
     cv::Rect Rec(position1[0][0]/2.2,position1[0][1]/2, 150, 150);
     rectangle(LoadedImage, Rec, Scalar(255), 1, 8, 0);
     
     
     
     //Select area described by REC and result write to the Roi
     Mat Roi = LoadedImage(Rec);
     //resize(Roi, Roi, Size(220,220));
     //  rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
     Match(CompareImage1, Roi, position2,950,j_2);
     //resize(Roi, Roi, Size(180,180));
     //cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 100, 100);
     //rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     
     
     if ((position2[0][0]/2.8+100)<150 && (position2[0][1]/2.2+100)<150 )
     {
     cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 100, 100);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     
     }
     cout<<" 1 "<<endl;
     }
     else if((position2[0][0]/2.8+100)>150 && (position2[0][1]/2.2+100)<150)
     {
     cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 150-position2[0][0]/2.8, 100);
     cv::rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     
     //    if (Roi1.rows>0 && Roi1.cols>0)
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 2 "<<endl;
     }
     else if((position2[0][0]/2.8+100)<150 && (position2[0][1]/2.2+100)>150)
     {
     cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 100, 150-position2[0][1]/2.2);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     // imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 3 "<<endl;
     }
     else
     {
     cv::Rect Small(position2[0][0]/2.8,position2[0][1]/2.2, 150-position2[0][0]/2.8, 150-position2[0][1]/2.2);
     rectangle(Roi, Small, Scalar(255), 1, 8, 0);
     //  imshow("Roi draw Rectangle", Roi);
     //   waitKey(0);
     
     Mat Roi1;
     if(Small.x >= 0 && Small.y >= 0 && Small.width + Small.x < Roi.cols && Small.height + Small.y < Roi.rows)
     {
     Roi1= Roi(Small);
     //    if (Roi1.rows>0 && Roi1.cols>0 )
     Corner(Roi1,position_square_1, position_square_2, position_square_3, position_square_4);
     }
     cout<<" 4 "<<endl;
     }
     
     position_square2[0][0]=position_square_1[0][0]+position2[0][0]/2.8+position1[0][0]/2.2;
     position_square2[0][1]=position_square_1[0][1]+position2[0][1]/2.2+position1[0][1]/2;
     position_square2[1][0]=position_square_2[0][0]+position2[0][0]/2.8+position1[0][0]/2.2;
     position_square2[1][1]=position_square_2[0][1]+position2[0][1]/2.2+position1[0][1]/2;
     position_square2[2][0]=position_square_3[0][0]+position2[0][0]/2.8+position1[0][0]/2.2;
     position_square2[2][1]=position_square_3[0][1]+position2[0][1]/2.2+position1[0][1]/2;
     position_square2[3][0]=position_square_4[0][0]+position2[0][0]/2.8+position1[0][0]/2.2;
     position_square2[3][1]=position_square_4[0][1]+position2[0][1]/2.2+position1[0][1]/2;
     
     int a[1][2];
     for (int i=0; i<3;i++)
     {
     for (int j=0; j<3; j++)
     {
     a[0][0]=0;
     a[0][1]=0;
     if((position_square2[j][0]*position_square2[j][0]+position_square2[j][1]*position_square2[j][1])>(position_square2[j+1][0]*position_square2[j+1][0]+position_square2[j+1][1]*position_square2[j+1][1]))
     {
     a[0][0]=position_square2[j][0];
     a[0][1]=position_square2[j][1];
     position_square2[j][0]=position_square2[j+1][0];
     position_square2[j][1]=position_square2[j+1][1];
     position_square2[j+1][0]=a[0][0];
     position_square2[j+1][1]=a[0][1];
     }
     }
     }
     if(position_square2[1][1]>position_square2[2][1])
     {
     a[0][0]=0;
     a[0][1]=0;
     a[0][0]=position_square2[1][0];
     a[0][1]=position_square2[1][1];
     position_square2[1][0]=position_square2[2][0];
     position_square2[1][1]=position_square2[2][1];
     position_square2[2][0]=a[0][0];
     position_square2[2][1]=a[0][1];
     
     }
     
     cv::Rect WhereRec(position1[0][0]/2.2,position1[0][1]/2, Roi.cols, Roi.rows);
     // This copy Roi Image into loaded on position Where rec
     Roi.copyTo(LoadedImage(WhereRec));
     
     
     Transform(LoadedImage,position_square2,object_1,object_2,position);
     
     if(Pt1.x>0&& Pt1.y>0&& position_square2[0][0]>position1[0][0]/2.2&&position_square2[0][0]<position1[0][0]/2.2+150&&position_square2[0][1]>position1[0][1]/2&&position_square2[0][1]<position1[0][1]/2+150&&position[0][0]>30&&position[0][0]<46)
     {
     cout<<"distance1 "<<position[0][0]<<" theta1 "<<position[0][1]<<endl;
     
     {
     object_poisition[0][0]+=position[0][0];
     object_poisition[0][1]+=position[0][1];
     times++;
     }
     cout<<"times  "<<times<<endl;
     
     if(times>=2)
     {
     x_x=object_poisition[0][0]/times;
     y_y=object_poisition[0][1]/times;
     cout<<"times   times"<<endl;
     times=0;
     }
     cout<<"x_x "<<x_x<<endl;
     
     if(joint_1<=0.01&&abs(joint_2-1.05)<0.01&&x_x>30&&x_x<46)
     {
     cout<<"11111111111"<<endl;
     // [self.videoCamera stop];
     shoulderPublisher = [[RBManager defaultManager] addPublisher:@"/choose_begin" messageType:@"geometry_msgs/Point"];
     shoulderPublisher.label = @"Choose";
     
     CGFloat x = x_x;
     CGFloat y = 0;
     CGFloat theta = y_y;
     
     PointMessage * shoulder = [[PointMessage alloc] init];
     shoulder.x = [NSNumber numberWithFloat:x];
     shoulder.y = [NSNumber numberWithFloat:y];
     shoulder.z = [NSNumber numberWithFloat:theta];
     [shoulderPublisher publish:shoulder];
     
     object_poisition[0][0]=0;
     object_poisition[0][1]=0;
     x_x=0;
     y_y=0;
     }
     }
     
     }
     }
     //  }
     
     //    */
    
    cv::rectangle(LoadedImage, Pt1, Pt2, cvScalar(255),5);
    //cvtColor(LoadedImage, image, CV_GRAY2BGR);
    LoadedImage.copyTo(image);
    // cv::resize(image, image, cv::Size(720,1280));
    cout<<"joint_11 "<<joint_1<<endl;
    cout<<"joint_22 "<<joint_2<<endl;
    return (cv::Mat &)image;
    
    
}



void Transform( Mat src, int  square_pisition[4][2], int object_1[1][2],int object_2[1][2],float position[1][2])
{
    // cv::Mat src= cv::imread("/Users/ghm/Documents/TEST/18-1.jpg",1);
    // if (!src.data)
    //     return 0;
    vector<cv::Point> not_a_rect_shape;
    not_a_rect_shape.push_back(cv::Point(square_pisition[0][0],square_pisition[0][1]));
    not_a_rect_shape.push_back(cv::Point(square_pisition[1][0],square_pisition[1][1]));
    not_a_rect_shape.push_back(cv::Point(square_pisition[2][0],square_pisition[2][1]));
    not_a_rect_shape.push_back(cv::Point(square_pisition[3][0],square_pisition[3][1]));
    
    vector<Point3f> vec;
    vec.push_back(Point3f(object_1[0][0],object_1[0][1],1));
    vec.push_back(Point3f(object_2[0][0],object_2[0][1],1));
    Mat srcMat = Mat(vec).reshape(1).t();
    //  transpose(srcMat, srcMat);
    
    //  vector<Point3d> object;
    //  object.push_back(Point3d(339,285,1));
    //  object.push_back(Point3d(397,285,1));
    /*
     not_a_rect_shape.push_back(Point(96,305));
     not_a_rect_shape.push_back(Point(127,286));
     not_a_rect_shape.push_back(Point(114,333));
     not_a_rect_shape.push_back(Point(146,312));
     
     */
    // For debugging purposes, draw green lines connecting those points
    // and save it on disk
    const cv::Point* point = &not_a_rect_shape[0];
    int n = (int )not_a_rect_shape.size();
    Mat draw = src.clone();
    polylines(draw, &point, &n, 1, true, Scalar(0, 255, 0), 3, CV_AA);
    // imwrite( "draw.jpg", draw);
    //  topLeft, topRight, bottomRight, bottomLeft
    cv::Point2f src_vertices[4];
    src_vertices[0] = not_a_rect_shape[0];
    src_vertices[1] = not_a_rect_shape[1];
    src_vertices[2] = not_a_rect_shape[2];
    src_vertices[3] = not_a_rect_shape[3];
    
    Point2f dst_vertices[4];
    dst_vertices[0] = cv::Point(float(42.5),float(608.5));
    dst_vertices[1] = cv::Point(float(109.5),float(605.5));
    dst_vertices[2] = cv::Point(float(41.5),float(680));
    dst_vertices[3] = cv::Point(float(107.5),float(680));
    Mat warpMatrix = getPerspectiveTransform(src_vertices, dst_vertices);
    cv::Mat rotated;
    warpPerspective(src, rotated, warpMatrix, cv::Size(600,800), INTER_LINEAR, BORDER_CONSTANT);
    //  cv::transform(object, object, warpMatrix);
    warpMatrix.convertTo(warpMatrix,CV_32FC1);
    Mat dstMat = warpMatrix*srcMat;
    Point2f dst;
    //  cout<<"Object"<<dstMat.at<float>(0,0)<<" "<<dstMat.at<float>(1,0)<<" "<<dstMat.at<float>(2,0)<<endl;
    //  cout<<"Object"<<dstMat.at<float>(0,1)<<" "<<dstMat.at<float>(1,1)<<" "<<dstMat.at<float>(2,1)<<endl;
    circle(rotated, cv::Point(dstMat.at<float>(0,0)/dstMat.at<float>(2,0),dstMat.at<float>(1,0)/dstMat.at<float>(2,0)), 3, Scalar(0,255,0));
    circle(rotated, cv::Point(dstMat.at<float>(0,1)/dstMat.at<float>(2,1),dstMat.at<float>(1,1)/dstMat.at<float>(2,1)), 3, Scalar(0,255,0));
    float distance,theta;
    distance=sqrt(((dstMat.at<float>(0,0)/dstMat.at<float>(2,0)+dstMat.at<float>(0,1)/dstMat.at<float>(2,1))/2-109.5+227.8)*((dstMat.at<float>(0,0)/dstMat.at<float>(2,0)+dstMat.at<float>(0,1)/dstMat.at<float>(2,1))/2-109.5+227.8)+((dstMat.at<float>(1,0)/dstMat.at<float>(2,0)+dstMat.at<float>(1,1)/dstMat.at<float>(2,1))/2-605.5)*((dstMat.at<float>(1,0)/dstMat.at<float>(2,0)+dstMat.at<float>(1,1)/dstMat.at<float>(2,1))/2-605.5))*5/67;
    cout<<"distance "<<distance<<"cm"<<endl;
    theta=atan2(abs(((dstMat.at<float>(1,0)/dstMat.at<float>(2,0))+(dstMat.at<float>(1,1)/dstMat.at<float>(2,1)))/2-605.5), abs(((dstMat.at<float>(0,0)/dstMat.at<float>(2,0))+(dstMat.at<float>(0,1)/dstMat.at<float>(2,1)))/2-109.5+227.8));
    cout<<"theta "<<theta<<endl;
    
    position[0][0]=distance;
    position[0][1]=theta;
    
    //  cout<<"Object"<<object<<endl;
    
    // Display the image
    //  cv::namedWindow( "Original Image");
    // cv::imshow( "Original Image",src);
    //  cv::namedWindow( "warp perspective");
    //  cv::imshow( "warp perspective",rotated);
    //  imwrite( "result.jpg",src);
    //  cout<<"H="<<warpMatrix<<endl;
    // cv::waitKey();
    //    return 0;
}

void Match(Mat img_object, Mat img_scene, int lenght[1][2],int m, int n[1][1])
{
    // if( argc != 3 )
    // { readme(); return -1; }
    
    //Mat img_object = imread( "/Users/ghm/Documents/TEST/12-4.jpg", CV_LOAD_IMAGE_GRAYSCALE );
    //   resize(img_object, img_object, Size(300,300));
    //   Mat img_scene = imread( "/Users/ghm/Documents/TEST/28.jpg",1 );
    //   resize(img_scene, img_scene, Size(900,1200));
    
    
    
    
    //    if( !img_object.data || !img_scene.data )
    //    { std::cout<< " --(!) Error reading images " << std::endl; return -1; }
    
    //-- Step 1: Detect the keypoints using SURF Detector
    n[0][0]=0;
    int minHessian = m;//600;
    
    SurfFeatureDetector detector( minHessian );
    
    std::vector<KeyPoint> keypoints_object, keypoints_scene;
    
    detector.detect( img_object, keypoints_object );
    detector.detect( img_scene, keypoints_scene );
    
    //-- Step 2: Calculate descriptors (feature vectors)
    SurfDescriptorExtractor extractor;
    
    Mat descriptors_object, descriptors_scene;
    
    extractor.compute( img_object, keypoints_object, descriptors_object );
    extractor.compute( img_scene, keypoints_scene, descriptors_scene );
    
    //-- Step 3: Matching descriptor vectors using FLANN matcher
    FlannBasedMatcher matcher;
    std::vector< DMatch > matches;
    
    if (keypoints_scene.size()>0 && keypoints_scene.size()>0)
    {
        matcher.match( descriptors_object, descriptors_scene, matches );
        
        
        double max_dist = 0; double min_dist = 100;
        
        //-- Quick calculation of max and min distances between keypoints
        for( int i = 0; i < descriptors_object.rows; i++ )
        { double dist = matches[i].distance;
            if( dist < min_dist ) min_dist = dist;
            if( dist > max_dist ) max_dist = dist;
        }
        
        //  printf("-- Max dist : %f \n", max_dist );
        //  printf("-- Min dist : %f \n", min_dist );
        
        //-- Draw only "good" matches (i.e. whose distance is less than 3*min_dist )
        std::vector< DMatch > good_matches;
        
        for( int i = 0; i < descriptors_object.rows; i++ )
        { if( matches[i].distance < 3*min_dist )
        { good_matches.push_back( matches[i]); }
        }
        
        Mat img_matches;
        drawMatches( img_object, keypoints_object, img_scene, keypoints_scene,
                    good_matches, img_matches, Scalar::all(255), Scalar::all(255),
                    vector<char>(), DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
        
        //-- Localize the object
        std::vector<Point2f> obj;
        std::vector<Point2f> scene;
        
        for( int i = 0; i < good_matches.size(); i++ )
        {
            //-- Get the keypoints from the good matches
            obj.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
            scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
        }
        
        if(obj.size()>=4&&scene.size()>=4)
        {
        Mat H = findHomography( obj, scene, CV_RANSAC );
        
        //-- Get the corners from the image_1 ( the object to be "detected" )
        std::vector<Point2f> obj_corners(4);
        obj_corners[0] = cvPoint(0,0); obj_corners[1] = cvPoint( img_object.cols, 0 );
        obj_corners[2] = cvPoint( img_object.cols, img_object.rows ); obj_corners[3] = cvPoint( 0, img_object.rows );
        std::vector<Point2f> scene_corners(4);
        
        perspectiveTransform( obj_corners, scene_corners, H);
        
        //-- Draw lines between the corners (the mapped object in the scene - image_2 )
        line( img_matches, scene_corners[0] + Point2f( img_object.cols, 0), scene_corners[1] + Point2f( img_object.cols, 0), Scalar(0, 255, 0), 4 );
        line( img_matches, scene_corners[1] + Point2f( img_object.cols, 0), scene_corners[2] + Point2f( img_object.cols, 0), Scalar( 0, 255, 0), 4 );
        line( img_matches, scene_corners[2] + Point2f( img_object.cols, 0), scene_corners[3] + Point2f( img_object.cols, 0), Scalar( 0, 255, 0), 4 );
        line( img_matches, scene_corners[3] + Point2f( img_object.cols, 0), scene_corners[0] + Point2f( img_object.cols, 0), Scalar( 0, 255, 0), 4 );
        //  cout<<scene_corners[0]<<endl;
        
        lenght[0][0] = (scene_corners[0].x+scene_corners[1].x+scene_corners[2].x+scene_corners[3].x)/4;
        lenght[0][1] = (scene_corners[0].y+scene_corners[1].y+scene_corners[2].y+scene_corners[3].y)/4;
        n[0][0]=1;
        }
        
    }
    else{
        n[0][0]=0;
    }
    
    // resize(img_matches, img_matches, Size(480,600));
    // Rect Rec(scene_corners[0].x+img_object.cols-100, scene_corners[1].y-100, 200, 200);
    // rectangle(img_matches, Rec, Scalar(255), 1, 8, 0);
    // Mat Roi = img_matches(Rec);
    // cvtColor(Roi, Roi, CV_RGB2GRAY);
    //  Corner(Roi);
    // rectangle(Roi, Point(10,10), Point(30,30), Scalar(0,255,0));
    
    // imshow("Step 3 Draw selected Roi", Roi);
    
    
    //-- Show detected matches
    //imshow( "Good Matches & Object detection", img_matches );
    //  resize(img_scene, img_scene, Size(600,800));
    
    //waitKey(0);
    
    //   return 0;
}

/** @function readme */
void readme()
{ std::cout << " Usage: ./SURF_descriptor <img1> <img2>" << std::endl; }

void Corner(Mat img, int position_1[1][2],int position_2[1][2],int position_3[1][2],int position_4[1][2])
{
    const double l=20;
    // Mat img = imread("/Users/ghm/Documents/TEST/26.jpg", 0);
    //cvNamedWindow("img", 1);
    // imshow("img", img);
    Mat dst(img.rows,img.cols,8,1);
    int threshold = Otsu(img);//最大类间方差阈值分割
    //  printf("threshold = %d\n", threshold);
    cv::threshold(img,dst,threshold,255,CV_THRESH_BINARY);
    
    
    //cvNamedWindow("dst", 1);
    //imshow("dst", dst);
    cv::Rect roi(30,30,20,20);//去除复杂背景
    
    Mat img1(dst.rows,dst.cols,dst.depth(),dst.channels());
    
    if(dst.rows>0 && dst.cols>0)
    {
        
        for (int y = 0; y < img1.cols; y++)
        {
            for (int x = 0; x < img1.rows; x++)
            {
                //            cvSet2D(img1, y, x, cvScalarAll(255));
                img1.at<uchar>(y,x)=255;
            }
        }
        cv::Rect roi1(30, 30, 20, 20);
        //cvNamedWindow("img1");
        //imshow("img1", img1);
        
        //  cvSetImageROI(dst, roi);
        Mat Roi = dst(roi);
        Mat Roi2=img1(roi1);
        // cvSetImageROI(img1, roi1);
        //    cvCopy(dst, img1);
        dst.copyTo(img1);
        //    cvResetImageROI(dst);
        //    cvResetImageROI(img1);
        
        // cvNamedWindow("result", 1);
        //imshow("result", img1);
        
        //    IplImage*edge = cvCreateImage(cvGetSize(img1), 8, 1);//canny边缘检测
        Mat edge(img1.rows,img1.cols,8,1);
        int edgeThresh = 1;
        Canny(img1, edge, edgeThresh, edgeThresh * 3, 3);
        
        // cvNamedWindow("canny", 1);
        // imshow("canny", edge);
        int count = 0;
        for (int yy = 0; yy < edge.cols; yy++)//统计边缘图像中共有多少个黑色像素点
        {
            for (int xx = 0; xx < edge.rows; xx++)
            {
                //CvScalar ss = (255);
                //  double ds = cvGet2D(edge, yy, xx).val[0];
                double ds = edge.at<uchar>(yy,xx);
                if (ds == 0)
                    count++;
            }
        }
        //   cout<<"count "<<count<<endl;
        int dianshu_threshold = (100*100-count)/ 4;//将白色像素点数的四分之一作为hough变换的阈值
        //   cout<<"dianshu_threshold "<<dianshu_threshold<<endl;
        //   IplImage* houghtu = cvCreateImage(cvGetSize(edge), IPL_DEPTH_8U, 1);//hough直线变换
        Mat houghtu(edge.rows,edge.cols,edge.depth(),edge.channels());
        //   edge.copyTo(houghtu);
        // imshow("1", houghtu);
        
        //    CvMemStorage*storage = cvCreateMemStorage();
        vector<Vec2f> lines;
        lines={0,0};
        int i,j,k,m,n;
        while (true)//循环找出合适的阈值，使检测到的直线的数量在8-12之间
        {
            //  lines = HoughLines(edge, storage, 1, CV_PI / 180, dianshu_threshold, 0, 0);
            HoughLines(edge, lines, 1, CV_PI/180,dianshu_threshold,0,0);
            int line_number = lines.size();
            //  cout<<"line_number"<<line_number<<endl;
            if (line_number <8)
            {
                dianshu_threshold = dianshu_threshold - 2;
            }
            else if (line_number > 12)
            {
                dianshu_threshold = dianshu_threshold +1;
            }
            else
            {
                //      printf("line_number=%d\n", line_number);
                break;
            }
        }
        
        int A = 10;
        double B = CV_PI / 10;
        
        //   vector<Vec2f>::iterator lsave=lines.begin();
        
        
        while (1)
        {
            for (i = 0; i <lines.size(); i++)//将多条非常相像的直线剔除
            {
                for (j = 0; j < lines.size()&& i <lines.size(); j++)
                {
                    
                    if (j != i)
                    {
                        Vec2f line1 = lines[i];
                        Vec2f line2 = lines[j];
                        float rho1 = line1[0];
                        float threta1 = line1[1];
                        float rho2 = line2[0];
                        float threta2 = line2[1];
                        //     cout<<"i "<<i<<endl;
                        //     cout<<"j "<<j<<endl;
                        //     cout<<"rho1 "<<rho1<<endl;
                        //      cout<<"threta1 "<<threta1<<endl;
                        //       cout<<"rho2 "<<rho2<<endl;
                        //       cout<<"threta2 "<<threta2<<endl;
                        
                        if (abs(rho1 - rho2) < A && abs(threta1 - threta2) < B)
                        {
                            lines.erase(lines.begin()+j);
                            //          printf("123\n");
                        }
                        //  lsave=lines.begin();
                        //      cout<<"lines"<<lines.size()<<endl;
                    }
                }
            }
            
            if (lines.size() > 4)//剔除一圈后如何直线的数量大于4，则改变A和B，继续删除相似的直线
            {
                A = A + 1;
                B = B + CV_PI / 180;
            }
            else
            {
                //    printf("lines->total=%lu\n", lines.size());
                break;
            }
        }
        
        
        
        
        for (k= 0; k < lines.size(); k++)//画出直线
        {
            Vec2f line3 = lines[k];
            float rho = line3[0];//r=line[0]
            float threta = line3[1];//threta=line[1]
            //  cout<<"rho "<<rho<<endl;
            
            CvPoint pt1, pt2;
            double a = cos(threta), b = sin(threta);
            double x0 = a*rho;
            double y0 = b*rho;
            pt1.x = cvRound(x0 + 100 * (-b));//定义直线的终点和起点，直线上每一个点应该满足直线方程r=xcos(threta)+ysin(threta);
            pt1.y = cvRound(y0 + 100 * (a));
            pt2.x = cvRound(x0 - 1200 * (-b));
            pt2.y = cvRound(y0 - 1200 * (a));
            line(houghtu, pt1, pt2, CV_RGB(0, 255, 255), 1, 8);
            //   cout<<"pt1.x "<<pt1.x<<endl;
            //   cout<<"pt1.y "<<pt1.y<<endl;
        }
        const double C = CV_PI / 12;
        //   const double D = CV_PI / 1.5;
        int num = 0;
        CvPoint arr[8] = { { 0, 0 } };
        for (m = 0; m < lines.size(); m++)//画出直线的交点
        {
            for (n = 0; n < lines.size(); n++)
            {
                if (n!= m)
                {
                    Vec2f Line1 = lines[m];
                    Vec2f Line2 = lines[n];
                    float Rho1 = Line1[0];
                    float Threta1 = Line1[1];
                    float Rho2 =Line2[0];
                    float Threta2 = Line2[1];
                    //   cout<<"Rho1 "<<Rho2<<endl;
                    
                    if ((abs(Threta1 - Threta2) > C) )
                    {
                        double a1 = cos(Threta1), b1 = sin(Threta1);
                        double a2 = cos(Threta2), b2 = sin(Threta2);
                        CvPoint pt;
                        pt.x = (Rho2*b1 - Rho1*b2) / (a2*b1 - a1*b2);//直线交点公式
                        // pt.y = (Rho1 - a1*pt.x) / b1;
                        pt.y = (Rho1*a2 - Rho2*a1)/ (a2*b1 - a1*b2);
                        circle(houghtu, pt, 3, CV_RGB(255, 255, 0));
                        //      cout<<"m "<<m<<endl;
                        //      cout<<"n "<<n<<endl;
                        // pt.x=pt.x+100;
                        // pt.y=pt.y+150;
                        arr[num++] = pt;//将点的坐标保存在一个数组中
                    }
                }
                
            }
        }
        /*
         printf("num=%d\n", num);
         printf("arr[0].x=%d\n", arr[0].x);
         printf("arr[0].y=%d\n", arr[0].y);
         printf("arr[1].x=%d\n", arr[1].x);
         printf("arr[1].y=%d\n", arr[1].y);
         printf("arr[2].x=%d\n", arr[2].x);
         printf("arr[2].y=%d\n", arr[2].y);
         printf("arr[3].x=%d\n", arr[3].x);
         printf("arr[3].y=%d\n", arr[3].y);
         printf("arr[4].x=%d\n", arr[4].x);
         printf("arr[4].y=%d\n", arr[4].y);
         printf("arr[5].x=%d\n", arr[5].x);
         printf("arr[5].y=%d\n", arr[5].y);
         printf("arr[6].x=%d\n", arr[6].x);
         printf("arr[6].y=%d\n", arr[6].y);
         printf("arr[7].x=%d\n", arr[7].x);
         printf("arr[7].y=%d\n", arr[7].y);
         */
        
        CvPoint arr1[8] = { { 0, 0 } };//将重复的角点剔除
        int num1 = 0;
        for (int r = 0; r < 8; r++)
        {
            int s = 0;
            for (; s < num1; s++)
            {
                if (abs(arr[r].x - arr1[s].x) <= 2 && abs(arr[r].y - arr1[s].y) <= 2)
                    break;
            }
            if (s == num1)
            {
                arr1[num1] = arr[r];
                num1++;
            }
            
        }
        CvPoint arr2[8] = { { 0, 0 } };//将重复的角点剔除
        int num2 = 0;
        for (int r2 = 0; r2 < 8; r2++)
        {
            int s2 = 0;
            for (; s2 < num2; s2++)
            {
                //if (abs(arr1[r2].x - arr2[s2].x) <= 2 && abs(arr1[r2].y - arr2[s2].y) <= 2)
                if(sqrt((arr1[r2].x-arr2[s2].x)*(arr1[r2].x-arr2[s2].x)+(arr1[r2].y-arr2[s2].y)*(arr1[r2].y-arr2[s2].y))<l)
                    break;
            }
            if (s2 == num2)
            {
                arr2[num2] = arr1[r2];
                num2++;
            }
            
        }
        
        /*
         printf("num1=%d\n", num1);
         printf("arr2[0].x=%d\n", arr2[0].x);
         printf("arr2[0].y=%d\n", arr2[0].y);
         printf("arr2[1].x=%d\n", arr2[1].x);
         printf("arr2[1].y=%d\n", arr2[1].y);
         printf("arr2[2].x=%d\n", arr2[2].x);
         printf("arr2[2].y=%d\n", arr2[2].y);
         printf("arr2[3].x=%d\n", arr2[3].x);
         printf("arr2[3].y=%d\n", arr2[3].y);
         printf("arr2[4].x=%d\n", arr2[4].x);
         printf("arr2[4].y=%d\n", arr2[4].y);
         printf("arr2[5].x=%d\n", arr2[5].x);
         printf("arr2[5].y=%d\n", arr2[5].y);
         printf("arr2[6].x=%d\n", arr2[6].x);
         printf("arr2[6].y=%d\n", arr2[6].y);
         printf("arr2[7].x=%d\n", arr2[7].x);
         printf("arr2[7].y=%d\n", arr2[7].y);
         
         */
        position_1[0][0]=arr2[0].x;
        position_1[0][1]=arr2[0].y;
        position_2[0][0]=arr2[1].x;
        position_2[0][1]=arr2[1].y;
        position_3[0][0]=arr2[2].x;
        position_3[0][1]=arr2[2].y;
        position_4[0][0]=arr2[3].x;
        position_4[0][1]=arr2[3].y;
        
        //   cout<<"position[2][0] "<<position_2[0][0]<<endl;
        //   cout<<"position[2][1] "<<position_2[0][1]<<endl;
        //   cout<<"img.size "<<img.size()<<endl;
        
        for (int w = 0; w < 8; w++)
        {
            CvPoint ps;
            ps = arr2[w];
            circle(img, ps, 2, CV_RGB(255,0,0),-1);
        }
        
        
        // cvNamedWindow("img", 1);
        // imshow("img", img);
        // cvNamedWindow("houghtu", 1);
        // imshow("houghtu", houghtu);
        
    }
    
    
    
    //  cout<<"houghtu.rows "<<houghtu.rows<<endl;
    //  cout<<"houghtu,cols "<<houghtu.cols<<endl;
    //  cout<<"houghtu.channels "<<houghtu.channels()<<endl;
    //  cout<<"houghtu.depth "<<houghtu.depth()<<endl;
    
    // cvWaitKey(-1);
    
    //     cvReleaseImage(&img);
    //     cvReleaseImage(&dst);
    
    
    //  cvDestroyWindow("dst");
    //return arr2[8];
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
        w += histogram[i];  //假设当前灰度i为阈值, 0~i 灰度的像素(假设像素值在此范围的像素叫做前景像素) 所占整幅图像的比例
        u += i * histogram[i];  // 灰度i 之前的像素(0~i)的平均灰度值： 前景像素的平均灰度值
        
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


- (void)didReceiveMemoryWarning {[super didReceiveMemoryWarning];}




@end
