# Autonomous Domestic Assistant Robot 
This is a domestic mobile robotic system combined with a manipulator, object recognition and  SLAM technique with mobile devices to assist human in an indoor environment based on multi ROS packages and OpenCV.

This project utilizes the ROS gmapping and amcl package for mapping and navigation, ROS openni_launch package for object recognition and obtaining position information and ROS web_video_server package for sending image frame to ios devices through mjpg-streamer.

It also includes a class `Classifier` which is the `cascade_classification` trained from OpenCV C++ Cascade Classifier Training.
The whole recognition, picking and placing process show in following video:
https://youtu.be/sLj5nEyMdNI 

## Dependencies

* opencv2.framework
* Xcode 7.0 or 8.0 
* RBManager(https://github.com/wesgood/RBManager)
* turtlebot(https://github.com/turtlebot/turtlebot_apps)
* gmapping(https://github.com/ros-perception/slam_gmapping)
* amcl(https://github.com/ros-planning/navigation)
* openni_launch(https://github.com/ros-drivers/openni_launch)
* web_video_server(https://github.com/RobotWebTools/web_video_server)
