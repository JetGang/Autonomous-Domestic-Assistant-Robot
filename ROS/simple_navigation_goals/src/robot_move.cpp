#include <ros/ros.h>
#include <cv_bridge/cv_bridge.h>
#include "geometry_msgs/Point.h"
#include "std_msgs/Float64.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <math.h>
#include <move_base_msgs/MoveBaseAction.h>
#include <actionlib/client/simple_action_client.h>
#define PI 3.14159265
#define l1 115
#define l2 140 //real distance
#define l3 18

typedef actionlib::SimpleActionClient<move_base_msgs::MoveBaseAction> MoveBaseClient;

float theata=0.0;
float distance=0.0;
float back=1.0;
float end_signal=0.0;
float extra=0.0;
class ImageConverter
{
  ros::NodeHandle nh_;
  ros::Subscriber image_pose_sub_;
  ros::Subscriber extra_sub_;
  ros::Subscriber signal_sub_;
  //image_transport::Publisher image_pub_;
  ros::Publisher choose_sub_;
  ros::Publisher pose_signal_pub_;
  
public:
  ImageConverter()
  {
    // Subscrive to input video feed and publish output video feed
    image_pose_sub_ = nh_.subscribe("image_pose_move", 1, &ImageConverter::imageposeCb, this);
    //extra_sub_ = nh_.subscribe("extra", 1, &ImageConverter::extradistanceCb, this);
    //signal_sub_ = nh_.subscribe("pickup_end/command", 1, &ImageConverter::signalCb, this);
    choose_sub_ = nh_.advertise<geometry_msgs::Point>("/choose_begin",1);
    pose_signal_pub_ = nh_.advertise<std_msgs::Float64>("/pose_signal",1);

  }

//  void signalCb(std_msgs::Float64 msg_signal)
//  {
//	end_signal=msg_signal.data;
//  }
//  void extradistanceCb(std_msgs::Float64 msg_extra)
//  {
//	extra=msg_extra.data;
//	ROS_INFO("extra: %f", extra);
//  }

  void imageposeCb(geometry_msgs::Point msg)
  {
	std_msgs::Float64 pose_signal_2;
     	theata=msg.x;
     	distance=msg.y;
     	back=msg.z;
	if(back<0.1)
	{
	ROS_INFO("zPose: %f", theata);

	MoveBaseClient ac("move_base", true);

  	//wait for the action server to come up
  	while(!ac.waitForServer(ros::Duration(5.0))){
    	ROS_INFO("Waiting for the move_base action server to come up");
  	}

  	move_base_msgs::MoveBaseGoal goal;

  	//we'll send a goal to the robot to move 1 meter forward
  	goal.target_pose.header.frame_id = "base_link";
  	goal.target_pose.header.stamp = ros::Time::now();

  	goal.target_pose.pose.position.x = distance;
  	goal.target_pose.pose.position.y = 0.0;
  	goal.target_pose.pose.position.z = 0.0;
  	goal.target_pose.pose.orientation.x = 0.0;
  	goal.target_pose.pose.orientation.y = 0.0;
  	goal.target_pose.pose.orientation.z = sin(theata);
  	goal.target_pose.pose.orientation.w = cos(theata);

  	ROS_INFO("Sending goal");
  	ac.sendGoal(goal);

  	ac.waitForResult();

  	if(ac.getState() == actionlib::SimpleClientGoalState::SUCCEEDED){
    	ROS_INFO("Hooray, the base moved 1 meter forward");
	back=1.0;
	pose_signal_2.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_2);
	}
	}
  	else
	{
    	ROS_INFO("The base failed to move forward 1 meter for some reason");
	back=1.0;
	pose_signal_2.data=0.0;
	for(int i=0;i<3;i++)
	{
	pose_signal_pub_.publish(pose_signal_2);
	}
	}

	}
  }
  
};

int main(int argc, char* argv[])
{
  ros::init(argc, argv, "robot_move");

  ImageConverter ic;
  ros::spin();
  return 0;
}

