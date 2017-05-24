#include <ros/ros.h>
#include <image_transport/image_transport.h>
#include <cv_bridge/cv_bridge.h>
#include <sensor_msgs/image_encodings.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <sys/stat.h>

#include <opencv2/objdetect/objdetect.hpp>
#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

//#include <dynamic_reconfigure/server.h>
// #include "opencv_apps/FaceDetectionConfig.h"
// #include "opencv_apps/Face.h"
// #include "opencv_apps/FaceArray.h"
// #include "opencv_apps/FaceArrayStamped.h"

static const std::string OPENCV_WINDOW = "Image window";
using namespace std;
using namespace cv;

string face_cascade_name="/usr/share/opencv/haarcascades/haarcascade_frontalface_alt.xml";
CascadeClassifier face_cascade;

class ImageConverter
{
  ros::NodeHandle nh_;
  image_transport::ImageTransport it_;
  image_transport::Subscriber image_sub_;
  image_transport::Publisher image_pub_;

  //cv::CascadeClassifier eyes_cascade_;
    //pnh_->param("face_cascade_name", face_cascade_name, std::string("/usr/share/opencv/haarcascades/haarcascade_frontalface_alt.xml"));
    //pnh_->param("eyes_cascade_name", eyes_cascade_name, std::string("/usr/share/opencv/haarcascades/haarcascade_eye_tree_eyeglasses.xml"));

    //if( !face_cascade_.load( face_cascade_name ) ){ NODELET_ERROR("--Error loading %s", face_cascade_name.c_str()); };
  
public:
  ImageConverter()
    : it_(nh_)
  {
    // Subscrive to input video feed and publish output video feed
    image_sub_ = it_.subscribe("/camera/rgb/image_color", 1, 
      &ImageConverter::imageCb, this);
    image_pub_ = it_.advertise("/image_converter/output_video", 1);

    cv::namedWindow(OPENCV_WINDOW);
  }

  ~ImageConverter()
  {
    cv::destroyWindow(OPENCV_WINDOW);
  }

  void imageCb(const sensor_msgs::ImageConstPtr& msg)
  {
    cv_bridge::CvImagePtr cv_ptr;
    cv::Mat frame;
    if( !face_cascade.load( face_cascade_name ) ){ printf("--(!)Error loading\n"); };
    try
    {
      cv_ptr = cv_bridge::toCvCopy(msg, sensor_msgs::image_encodings::BGR8);
      frame = cv_bridge::toCvShare(msg,sensor_msgs::image_encodings::BGR8)->image;      
    }
    catch (cv_bridge::Exception& e)
    {
      ROS_ERROR("cv_bridge exception: %s", e.what());
      return;
    }

    // Draw an example circle on the video stream
    if (cv_ptr->image.rows > 60 && cv_ptr->image.cols > 60)
      cv::circle(cv_ptr->image, cv::Point(60, 80), 10, CV_RGB(255,0,0));
    
    cv::cvtColor(cv_ptr->image, cv_ptr->image, CV_BGR2GRAY);
    
    std::vector<cv::Rect> faces;
      cv::Mat frame_gray;
      //cv::resize(frame,frame,cv::Size(240,320));
      if ( frame.channels() > 1 ) {
        cv::cvtColor( frame, frame_gray, cv::COLOR_BGR2GRAY );
      } 
      else 
      {
        frame_gray = frame;
      }
      cv::equalizeHist( frame_gray, frame_gray );
      //-- Detect faces

      face_cascade.detectMultiScale( frame_gray, faces, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(30, 30) );

      for( size_t i = 0; i < faces.size(); i++ )
      {
        cv::Point center( faces[i].x + faces[i].width/2, faces[i].y + faces[i].height/2 );
        cv::ellipse( frame,  center, cv::Size( faces[i].width/2, faces[i].height/2), 0, 0, 360, cv::Scalar( 255, 0, 255 ), 2, 8, 0 );
//         opencv_apps::Face face_msg;
//         face_msg.face.x = center.x;
//         face_msg.face.y = center.y;
//         face_msg.face.width = faces[i].width;
//         face_msg.face.height = faces[i].height;
        }
      //-- Show what you got
    
    // Update GUI Window
    cv::imshow(OPENCV_WINDOW, frame);
      //-- Show what you got
    
    // Update GUI Window
    //cv::imshow(OPENCV_WINDOW, cv_ptr->image);
    cv::waitKey(3);
    
    // Output modified video stream
    //image_pub_.publish(frame->toImageMsg());
  }
};

int main(int argc, char** argv)
{
  ros::init(argc, argv, "image_converter");
  ImageConverter ic;
  ros::spin();
  return 0;
}

