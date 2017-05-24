#include <ros/ros.h>
#include <cv_bridge/cv_bridge.h>
#include "geometry_msgs/Point.h"
#include "std_msgs/Float64.h"
#include "std_msgs/Int64.h"
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

int place_signal=0;
float end_signal=1.0;//pickup end

class Navigation
{
  ros::NodeHandle nh_;
  ros::Subscriber navigation_signal_begin;
  ros::Subscriber signal_sub_;
  ros::Publisher navigation_signal_end;
  ros::Publisher close_kinect;
  ros::Publisher place_signal;
  
public:
  Navigation()
  {
    // Subscrive to input video feed and publish output video feed
    //navigation_signal_begin = nh_.subscribe("navigation_signal_begin", 1, &Navigation::navigationBegin, this);
    //extra_sub_ = nh_.subscribe("extra", 1, &ImageConverter::extradistanceCb, this);
    signal_sub_ = nh_.subscribe("pickup_end/command", 1, &Navigation::signalCb, this);
    //pickup_prepare = nh_.advertise<std_msgs::Int64>("up_signal",1);
    //pose_signal_pub_ = nh_.advertise<std_msgs::Float64>("/pose_signal",1);
    close_kinect = nh_.advertise<std_msgs::Int64>("close_distance_move",1);

  }


  void signalCb(std_msgs::Float64 msg_signal)
  {
	end_signal=msg_signal.data;
	std_msgs::Int64 place;
	std_msgs::Int64 close_distance_move;
	ros::Rate loopRate(15);
	if(end_signal<0.1)
	{
	int close_time=0;
	close_distance_move.data=1;

	   while(ros::ok())
	   {
	     close_kinect.publish(close_distance_move);
	     close_time++;
	     loopRate.sleep();
	     if(close_time>3)
	       break;
	    }
	
	end_signal=1.0;
	//tell the action client that we want to spin a thread by default
  	MoveBaseClient ac("move_base", true);

  	//wait for the action server to come up
  	while(!ac.waitForServer(ros::Duration(5.0))){
    	  ROS_INFO("Waiting for the move_base action server to come up");
  	  }

  	move_base_msgs::MoveBaseGoal goal;

  	//we'll send a goal to the robot to move 1 meter forward
  	goal.target_pose.header.frame_id = "map";
  	goal.target_pose.header.stamp = ros::Time::now();

  	goal.target_pose.pose.position.x =0.165;//-0.308;lab-33
  	goal.target_pose.pose.position.y = 0.113;//-2.779;//
  	goal.target_pose.pose.position.z = 0.0;
  	goal.target_pose.pose.orientation.x = 0.0;
  	goal.target_pose.pose.orientation.y = 0.0;
  	goal.target_pose.pose.orientation.z = 0.008;//-0.526;//
  	goal.target_pose.pose.orientation.w = 0.999;//0.851;//

  	ROS_INFO("Sending goal");
  	ac.sendGoal(goal);

  	ac.waitForResult();

  	if(ac.getState() == actionlib::SimpleClientGoalState::SUCCEEDED)
	{
    	   ROS_INFO("Hooray, the base moved 1 meter forward");
	   place.data=1;
	  
           /* 
	   int time=0;

	   while(ros::ok())
	   {
	     place_signal.publish(place);
	     time++;
	     loopRate.sleep();
	     if(time>3)
	       break;
	    }
           */
	}
 	else
	{
    	   ROS_INFO("The base failed to move forward 1 meter for some reason");		
	}	

	}
  }
//  void extradistanceCb(std_msgs::Float64 msg_extra)
//  {
//	extra=msg_extra.data;
//	ROS_INFO("extra: %f", extra);
//  }

/*
  void navigationBegin(std_msgs::Int64 msg)
  {
	std_msgs::Int64 end;
	std_msgs::Int64 pickup;
	begin_signal=msg.data;
        ROS_INFO("begin_signal: %d", begin_signal);
	if(begin_signal>0)
	{
	begin_signal=0;
	ros::Rate loopRate(15);
	//tell the action client that we want to spin a thread by default
  	MoveBaseClient ac("move_base", true);

  	//wait for the action server to come up
  	while(!ac.waitForServer(ros::Duration(5.0))){
    	  ROS_INFO("Waiting for the move_base action server to come up");
  	  }

  	move_base_msgs::MoveBaseGoal goal;

  	//we'll send a goal to the robot to move 1 meter forward
  	goal.target_pose.header.frame_id = "map";
  	goal.target_pose.header.stamp = ros::Time::now();

  	goal.target_pose.pose.position.x = 2.325; //-10.565;
  	goal.target_pose.pose.position.y = 0.171;//-5.694;
  	goal.target_pose.pose.position.z = 0.0;
  	goal.target_pose.pose.orientation.x = 0.0;
  	goal.target_pose.pose.orientation.y = 0.0;
  	goal.target_pose.pose.orientation.z = -0.042;//0.816;
  	goal.target_pose.pose.orientation.w = 0.999;//0.578;

  	ROS_INFO("Sending goal");
  	ac.sendGoal(goal);

  	ac.waitForResult();

  	if(ac.getState() == actionlib::SimpleClientGoalState::SUCCEEDED)
	{
    	   ROS_INFO("Hooray, the base moved 1 meter forward");
	   end.data=1;
	   pickup.data=1;

	   int time_0=0;

	   while(ros::ok())
	   {
	     pickup_prepare.publish(pickup);
	     time_0++;
	     loopRate.sleep();
	     if(time_0>2)
	       break;
	    }
	   
	   int time=0;

	   while(ros::ok())
	   {
	     navigation_signal_end.publish(end);
	     time++;
	     loopRate.sleep();
	     if(time>3)
	       break;
	    }
	}
 	else
	{
    	   ROS_INFO("The base failed to move forward 1 meter for some reason");	
           int time=0;

	   while(ros::ok())
	   {
	     navigation_signal_end.publish(end);
	     time++;
	     loopRate.sleep();
	     if(time>3)
	       break;
	    }	
	}

	}
  }
*/
  
};

int main(int argc, char* argv[])
{
  ros::init(argc, argv, "navigation_final_goals");

  Navigation ic;
  ros::spin();
  return 0;
}

