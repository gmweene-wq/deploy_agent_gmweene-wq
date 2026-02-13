AUTHOR: Griphen Mweene
email: gmweene@alustudent.com
#LINK TO YOUTUBE VIDEO EXPLAINING THE SCRIPT
https://youtu.be/GXTeG5A1v94
# Student Attendance Tracker - Project Factory

This shell script automates the creation and configuration of a Student Attendance Tracker project.

# How to Run the Script

Step 1: Make the script executable

chmod +x setup_attendance.sh

 Step 2: Run the script
./setup_attendance.sh or bash setup_attendance.sh

Step 3: Follow the prompts
a. Enter a directory name when prompted (e.g `v1`, `project1`)
b. Choose whether to update thresholds: Enter `y` or `n`
   - If yes, enter new Warning and Failure threshold values
   - Press Enter to use default values ( 75% and 50% )
c. Review the health check - The script will verify Python installation and directory structure

Step 4: Navigate to the created directory and run the attendance checker
bash
cd attendance_tracker_{your_directory_name put when prompted in step 1}
python3 attendance_checker.py

# How to Trigger the Archive Feature

The archive feature is automatically triggered when you interrupt during execution.

# To trigger the archive:
a. Run the script by pressing ./setup_attendance.sh
b. Press Ctrl+C at any time during the setup process

# What happens:
- The script catches the interrupt signal
- Creates an archive file: `attendance_tracker_{input}_archive.tar.gz`
- Removes the incomplete directory to keep workspace clean
- Displays a confirmation message

The archive file will be saved in the same directory where you ran the script.

