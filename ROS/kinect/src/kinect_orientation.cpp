#include <ros/ros.h>
#include <image_transport/image_transport.h>
#include <cv_bridge/cv_bridge.h>
#include <sensor_msgs/image_encodings.h>
#include "geometry_msgs/Point.h"
#include "std_msgs/Float64.h"
#include "std_msgs/Int64.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <math.h>
#include <vector>
#include <queue>
#include <map>

#define PI 3.14159265
#define l1 115
#define l2 140 //real distance
#define l3 18

int xPose=-10;
int yPose=-10;
float zPose=0.0;
float end_signal=0.0;
float extra=0.0;
float x[10],y[10],z[10];
int i=0;
geometry_msgs::Point orientation_object;
float x_orientation=0.0,y_orientation=0.0,z_orientation=0.0;

int sequence(float a[],int n)
{
    
    std::map<int,int> m;
    for(int i = 0;i<n;i++){
//        int num;
//        a[i]=num;
        
        m[a[i]]++;
    }
    
    std::map<int, int>::const_iterator cit = m.begin();
    int targetNum = cit->first;
    int mostFrequency = cit->second;
    for(++cit; cit!=m.end(); ++cit){
        if(cit->second > mostFrequency){
            targetNum = cit->first;
            mostFrequency = cit->second;
        }
    }

    
    return targetNum;
}

class ImageConverter
{
  ros::NodeHandle nh_;
  image_transport::ImageTransport it_;
  image_transport::Subscriber image_sub_;
  
  ros::Subscriber orientation_sub_;
  ros::Subscriber signal_sub_;
  ros::Publisher manipulator_pub_;
  ros::Publisher choose_sub_;
 // ros::Publisher orientation_pub;
  
public:
  ImageConverter()
    : it_(nh_)
  {
    // Subscrive to input video feed and publish output video feed
    
    orientation_sub_ = nh_.subscribe("/orientation", 1, &ImageConverter::extradistanceCb, this);
    signal_sub_ = nh_.subscribe("pickup_end/command", 1, &ImageConverter::signalCb, this);
    image_sub_ = it_.subscribe("/camera/depth_registered/image_raw", 1, &ImageConverter::imageCb, this);

    manipulator_pub_ = nh_.advertise<std_msgs::Int64>("pick_up_number", 1);
    choose_sub_ = nh_.advertise<geometry_msgs::Point>("/choose_begin",1);
    //orientation_pub = nh_.advertise<std_msgs::Float64>("/orientation_angle",1);

    //cv::namedWindow(OPENCV_WINDOW);
  }


  void signalCb(geometry_msgs::Point msg_orientation)
  {
   /*
        if(i<10)
        {
	x[i]=msg_orientation.x;
 	y[i]=msg_orientation.y;
	z[i]=msg_orientation.z;
	i++;
        }
	else
	{
	orientation_object.x=sequence(x,10);
	orientation_object.y=sequence(y,10);
	orientation_object.z=sequence(z,10);
	i=0;
	}
    */
  }
  void extradistanceCb(geometry_msgs::Point msg_orientation)
  {
	
	//if(i<5)
        //{
	
	orientation_object.x=msg_orientation.x;
 	orientation_object.y=msg_orientation.y;
	orientation_object.z=msg_orientation.z;
	//if(abs(x_orientation)>0.0)
	//{
	//x[i]=x_orientation;
 	//y[i]=y_orientation;
	//z[i]=z_orientation;
	//i++;
	//}
	//ROS_INFO("11: %d", i);

        //}
	/*
	else
	{
	orientation_object.x=sequence(x,5);
	orientation_object.y=sequence(y,5);
	orientation_object.z=sequence(z,5);
        ROS_INFO("orientation: %f", orientation_object.y);
	i=0;
	}
	*/
  }

 
  void imageCb(const sensor_msgs::ImageConstPtr& msg)
  {
    ros::Rate loopRate(10);
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

    int depth_1=0,depth_2=0;
    depth_1 = cv_ptr->image.at<short int>(cv::Point(490,320));//you can change 320,240 to your interested pixel
    ROS_INFO("Distance_1: %d", depth_1);

    depth_2 = cv_ptr->image.at<short int>(cv::Point(50,346));//you can change 320,240 to your interested pixel
    ROS_INFO("Distance_2: %d", depth_2);
    std_msgs::Int64 manipulator_number;
    int manipulator=0;
    if(depth_1<850)
    {
      manipulator=1;
    }
    else if(depth_2<790)
    {
      manipulator=2;
    }
    else
    {
      manipulator=0;
    }
    manipulator_number.data=manipulator;
    int i=0;
    while(ros::ok())
	{
	i++;
        manipulator_pub_.publish(manipulator_number);
	loopRate.sleep();
	if(i>2)
	break;
	}
   
    
  }
};


int main(int argc, char* argv[])
{
  ros::init(argc, argv, "kinect_orientation");
  ImageConverter ic;
  ros::spin();
  return 0;
}

