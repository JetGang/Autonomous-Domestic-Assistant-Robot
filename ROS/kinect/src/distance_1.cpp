#include <ros/ros.h>
#include <image_transport/image_transport.h>
#include <cv_bridge/cv_bridge.h>
#include <sensor_msgs/image_encodings.h>
#include "geometry_msgs/Point.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <math.h>
#define PI 3.14159265
#define l1 150
#define l2 14.8
#define l3 18

static const std::string OPENCV_WINDOW = "Image window";
int xPose=0;
int yPose=0;
float zPose=0.0;
class ImageConverter
{
  ros::NodeHandle nh_;
  image_transport::ImageTransport it_;
  image_transport::Subscriber image_sub_;
  ros::Subscriber image_pose_sub_;
  image_transport::Publisher image_pub_;
  
public:
  ImageConverter()
    : it_(nh_)
  {
    // Subscrive to input video feed and publish output video feed
    image_pose_sub_ = nh_.subscribe("image_pose", 1, &ImageConverter::imageposeCb, this);
    image_sub_ = it_.subscribe("/camera/depth/image_raw", 1, &ImageConverter::imageCb, this);


    //image_pub_ = it_.advertise("/image_converter/output_video", 1);

    //cv::namedWindow(OPENCV_WINDOW);
  }

  ~ImageConverter()
  {
    cv::destroyWindow(OPENCV_WINDOW);
  }

  void imageposeCb(geometry_msgs::Point msg)
  {
     xPose=int(msg.x*1.55);
     yPose=int(msg.y*1.5);
     zPose=msg.z;
//     if(xPose>0&&yPose>0)
//	{
//	ROS_INFO("xPose: %d", xPose);
//	ROS_INFO("yPose: %d", yPose);
//	}
  }
  void imageCb(const sensor_msgs::ImageConstPtr& msg)
  {
    cv_bridge::CvImagePtr cv_ptr;
    try
    {
      cv_ptr = cv_bridge::toCvCopy(msg, sensor_msgs::image_encodings::TYPE_16UC1);
    }
    catch (cv_bridge::Exception& e)
    {
      ROS_ERROR("cv_bridge exception: %s", e.what());
      return;
    }

    int depth=0;
    depth = cv_ptr->image.at<short int>(cv::Point(xPose,yPose));//you can change 320,240 to your interested pixel
    if(depth>=500&&depth<=1000)
    {
        float distance1=0.0;
	float distance2=0.0;
	float theata=0.0;
	distance1=depth*tan(zPose);
	distance2=sqrt(distance1*distance1+(depth-l1)*(depth-l1));
	theata=atan2(distance1,(depth-l1));
    	ROS_INFO("Depth: %d", depth);
	ROS_INFO("Depth1: %f", distance2);
	ROS_INFO("Theata: %f", theata);
	xPose=0;
	yPose=0;
	zPose=0.0;
    }
  }
};

int main(int argc, char** argv)
{
  ros::init(argc, argv, "distance");
  ImageConverter ic;
  ros::spin();
  return 0;
}

