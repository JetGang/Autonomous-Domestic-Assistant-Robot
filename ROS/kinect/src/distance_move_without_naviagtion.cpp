#include <ros/ros.h>
#include <image_transport/image_transport.h>
#include <cv_bridge/cv_bridge.h>
#include <sensor_msgs/image_encodings.h>
#include "geometry_msgs/Point.h"
#include "std_msgs/Float64.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <math.h>
#include <move_base_msgs/MoveBaseAction.h>
#include <actionlib/client/simple_action_client.h>
#define PI 3.14159265
#define l1 105
#define l2 110 //real distance
#define l3 18

typedef actionlib::SimpleActionClient<move_base_msgs::MoveBaseAction> MoveBaseClient;

static const std::string OPENCV_WINDOW = "Image window";
int xPose=-10;
int yPose=-10;
float zPose=0.0;
float end_signal=0.0;
float extra=0.0;
int count=0,count_1=0;
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
  ros::Publisher pose_signal_pub_;
  
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
    pose_signal_pub_ = nh_.advertise<std_msgs::Float64>("/pose_signal",1);


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
     MoveBaseClient ac_("move_base", true);
     xPose=int(msg.x*1.52);
     yPose=int(msg.y*1.4);
     zPose=-msg.z;
     if(xPose>0&&yPose>0)
	{
	ROS_INFO("xPose: %d", xPose);
	ROS_INFO("yPose: %d", yPose);
	ROS_INFO("zPose: %f", zPose);
	count++;
	std_msgs::Float64 pose_signal_1;
	pose_signal_1.data=1.0;
	for(int i=0;i<5;i++)
	{
	pose_signal_pub_.publish(pose_signal_1);
	}

	move_base_msgs::MoveBaseGoal goal;
	float x=0.0,z=0.0,w=0.0;
	if(fabs(zPose)>0.15)
	{
	std_msgs::Float64 pose_signal_2;

	while(!ac_.waitForServer(ros::Duration(5.0)))
	{
    	ROS_INFO("Waiting for the move_base action server to come up");
	}

	x=0.0;
	if(zPose<=0)
	{
	z=sin(-0.08);
	w=cos(-0.08);
	}
	else
	{
	z=sin(0.08);
	w=cos(0.08);
	}
  	//we'll send a goal to the robot to move 1 meter forward
  	goal.target_pose.header.frame_id = "base_link";
  	goal.target_pose.header.stamp = ros::Time::now();

  	goal.target_pose.pose.position.x = x;
  	goal.target_pose.pose.orientation.z = z;
  	goal.target_pose.pose.orientation.w = w;
	ROS_INFO("orientation.z:  %f", goal.target_pose.pose.orientation.z);
        ROS_INFO("orientation.w:  %f", goal.target_pose.pose.orientation.w);

  	ROS_INFO("Sending goal");
  	ac_.sendGoal(goal);

	ac_.waitForResult();

  	if(ac_.getState() == actionlib::SimpleClientGoalState::SUCCEEDED)
	{
	ROS_INFO("Hooray, the base rotated");
	pose_signal_2.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_2);
	} 

	}  	
	else
	{
    	ROS_INFO("The base failed to roatate for some reason");
	pose_signal_2.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_2);
	} 

	}

	}

	}
  }
  void imageCb(const sensor_msgs::ImageConstPtr& msg)
  {
	std_msgs::Float64 pose_signal_end;

    MoveBaseClient ac("move_base", true);
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
    if(depth>=500&&depth<=1000&&end_signal<0.1&&xPose>0&&yPose>0&&fabs(zPose)<=0.15)
    {
	count=0;
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
	theata=atan2(distance1,(depth-l2));
        choose_object_pose.x=(distance2/10.0)+extra;
        choose_object_pose.y=12;
        choose_object_pose.z=theata;
	ROS_INFO("Depth:  %d", depth);
	ROS_INFO("Depth1: %f", choose_object_pose.x);
	ROS_INFO("Theata: %f", choose_object_pose.z);
      	if(choose_object_pose.x<=45.5&&choose_object_pose.x>30)
	{
        choose_sub_.publish(choose_object_pose);
	std_msgs::Float64 pose_signal_2;
	pose_signal_2.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_2);
	} 
	//count_1=1;
	}
	else if(choose_object_pose.x>45.5)
	{
	std_msgs::Float64 pose_signal_1;
	std_msgs::Float64 pose_signal_2;
	//pose_signal_1.data=1.0;
	//pose_signal_pub_.publish(pose_signal_1);

	while(!ac.waitForServer(ros::Duration(5.0))){
    	ROS_INFO("Waiting for the move_base action server to come up");
	}

	move_base_msgs::MoveBaseGoal goal;
	float x=0.0,z=0.0,w=0.0;
	
	x=(depth-530)/1000.0;
	z=0.0;
	w=1.0;

	goal.target_pose.header.frame_id = "base_link";
  	goal.target_pose.header.stamp = ros::Time::now();

  	goal.target_pose.pose.position.x = x;
  	goal.target_pose.pose.orientation.z = z;
  	goal.target_pose.pose.orientation.w = w;

	ROS_INFO("orientation.x:  %f", goal.target_pose.pose.position.x);
        ROS_INFO("orientation.w:  %f", goal.target_pose.pose.orientation.w);

  	ROS_INFO("Sending goal");
  	ac.sendGoal(goal);

	ac.waitForResult();

  	if(ac.getState() == actionlib::SimpleClientGoalState::SUCCEEDED)
	{
	ROS_INFO("Hooray, the base moved forward");
	pose_signal_2.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_2);
	} 

	}  	
	else
	{
    	ROS_INFO("The base failed to move forward for some reason");
	pose_signal_2.data=0.0;

	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_2);
	} 

	}

	}
	xPose=-10;
	yPose=-10;
	zPose=0.0;
	distance2=0.0;
	extra=0.0;
    }
	if(count>5&&fabs(zPose)<=0.15)
	{
	move_base_msgs::MoveBaseGoal goal;

	while(!ac.waitForServer(ros::Duration(5.0))){
    	ROS_INFO("Waiting for the move_base action server to come up");
	}

	goal.target_pose.header.frame_id = "base_link";
  	goal.target_pose.header.stamp = ros::Time::now();

  	goal.target_pose.pose.position.x = 0.0;
  	goal.target_pose.pose.orientation.z = 0.999;
  	goal.target_pose.pose.orientation.w = 0.001;

	ROS_INFO("back orientation.z:  %f", goal.target_pose.pose.position.z);
        ROS_INFO("back orientation.w:  %f", goal.target_pose.pose.orientation.w);

  	ROS_INFO("Sending goal");
  	ac.sendGoal(goal);

	ac.waitForResult();

  	if(ac.getState() == actionlib::SimpleClientGoalState::SUCCEEDED)
	{
	ROS_INFO("Hooray, the base moved forward");
	
	move_base_msgs::MoveBaseGoal goal_1;

	while(!ac.waitForServer(ros::Duration(5.0))){
    	ROS_INFO("Waiting for the move_base action server to come up");
	}

	goal_1.target_pose.header.frame_id = "base_link";
  	goal_1.target_pose.header.stamp = ros::Time::now();

  	goal_1.target_pose.pose.position.x = 0.01;
  	goal_1.target_pose.pose.orientation.z = 0.0;
  	goal_1.target_pose.pose.orientation.w = 1.0;

	ROS_INFO("back orientation.x:  %f", goal_1.target_pose.pose.position.x);
        ROS_INFO("back orientation.w:  %f", goal_1.target_pose.pose.orientation.w);

  	ROS_INFO("Sending goal");
  	ac.sendGoal(goal_1);

	ac.waitForResult();

  	if(ac.getState() == actionlib::SimpleClientGoalState::SUCCEEDED)
	{
	ROS_INFO("Hooray, the base moved forward");
	pose_signal_end.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_end);
	}
	}  	
	else
	{
    	ROS_INFO("The base failed to move forward for some reason");
	pose_signal_end.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_end);
	}
	}

	}  	
	else
	{
    	ROS_INFO("The base failed to move forward for some reason");
	pose_signal_end.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_end);
	}
	}

	}
	pose_signal_end.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_end);
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

