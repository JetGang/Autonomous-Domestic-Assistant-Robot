#include <ros/ros.h>
#include <image_transport/image_transport.h>
#include <cv_bridge/cv_bridge.h>
#include <sensor_msgs/image_encodings.h>
#include "geometry_msgs/Point.h"
#include "std_msgs/Float64.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <math.h>
#define PI 3.14159265
#define l1 115
#define l2 140 //real distance
#define l3 18

static const std::string OPENCV_WINDOW = "Image window";
int xPose=-10;
int yPose=-10;
float zPose=0.0;
float end_signal=0.0;
float extra=0.0;
class ImageConverter
{
  ros::NodeHandle nh_;
  image_transport::ImageTransport it_;
  image_transport::Subscriber image_sub_;
  ros::Subscriber image_pose_sub_;
  ros::Subscriber extra_sub_;
  ros::Subscriber signal_sub_;
  //image_transport::Publisher image_pub_;
  ros::Publisher choose_sub_;
  
public:
  ImageConverter()
    : it_(nh_)
  {
    // Subscrive to input video feed and publish output video feed
    image_pose_sub_ = nh_.subscribe("image_pose", 1, &ImageConverter::imageposeCb, this);
    extra_sub_ = nh_.subscribe("extra", 1, &ImageConverter::extradistanceCb, this);
    signal_sub_ = nh_.subscribe("pickup_end/command", 1, &ImageConverter::signalCb, this);
    image_sub_ = it_.subscribe("/camera/depth/image_raw", 1, &ImageConverter::imageCb, this);

    //image_pub_ = it_.advertise("/image_converter/output_video", 1);
    choose_sub_ = nh_.advertise<geometry_msgs::Point>("/choose_begin",1);


    //cv::namedWindow(OPENCV_WINDOW);
  }

  ~ImageConverter()
  {
    cv::destroyWindow(OPENCV_WINDOW);
  }

  void signalCb(std_msgs::Float64 msg_signal)
  {
	end_signal=msg_signal.data;
  }
  void extradistanceCb(std_msgs::Float64 msg_extra)
  {
	extra=msg_extra.data;
	ROS_INFO("extra: %f", extra);
  }

  void imageposeCb(geometry_msgs::Point msg)
  {
     xPose=int(msg.x*1.52);
     yPose=int(msg.y*1.45);
     zPose=-msg.z;
     if(xPose>0&&yPose>0)
	{
	ROS_INFO("xPose: %d", xPose);
	ROS_INFO("yPose: %d", yPose);
	ROS_INFO("zPose: %f", zPose);
	}
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
    if(depth>=500&&depth<=1000&&end_signal<0.1&&xPose>0&&yPose>0)
    {
        geometry_msgs::Point choose_object_pose;
        float distance1=0.0;
	float distance2=0.0;
	float theata=0.0;
//	if(zPose>0)
//	{
//	   distance1=(depth*tan(zPose))+extra*10.0;
//	}
//	else
//	{
//	   distance1=(depth*tan(zPose))-extra*10.0;
//	}
	distance1=(depth*tan(zPose));//-extra*10.0);
	//distance1=distance1+20;
	distance2=sqrt(distance1*distance1+(depth-l1)*(depth-l1));
	theata=atan2(distance1,(depth-l2-10));
        choose_object_pose.x=(distance2/10.0)+extra;
        choose_object_pose.y=12;
        choose_object_pose.z=theata;
	ROS_INFO("Depth:  %f", distance1);
	ROS_INFO("Depth1: %f", choose_object_pose.x);
	ROS_INFO("Theata: %f", choose_object_pose.z);
      	if(choose_object_pose.x<45.5&&choose_object_pose.x>30)
	{
        choose_sub_.publish(choose_object_pose);
	}
	xPose=-10;
	yPose=-10;
	zPose=0.0;
	distance2=0.0;
	extra=0.0;
    }
  }
};

int main(int argc, char* argv[])
{
  ros::init(argc, argv, "distance");
  ImageConverter ic;
  ros::spin();
  return 0;
}

