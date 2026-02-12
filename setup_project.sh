#!/bin/bash

# Define cleanup function for signal trap
cleanup() {
    echo ""
    echo "Script interrupted! Cleaning up..."
    
    # Check if directory exists
    if [ -d "attendance_tracker_${input}" ]; then
        # Create archive of the incomplete project
        tar -czf "attendance_tracker_${input}_archive.tar.gz" "attendance_tracker_${input}"
        echo "Incomplete project archived as: attendance_tracker_${input}_archive.tar.gz"
        
        # Delete the incomplete directory
        rm -rf "attendance_tracker_${input}"
        echo "Incomplete directory removed."
    fi
    
    echo "Exiting script."
    exit 1
}

# Set up signal trap for SIGINT (Ctrl+C)
trap cleanup SIGINT

# Prompt user for directory name with validation
while true; do
    read -p "Enter the directory name: " input
    
    # Check if input is empty
    if [ -z "$input" ]; then
        echo "Error: Directory name cannot be empty. Please try again."
        continue
    fi
    
    # Check if directory already exists
    if [ -d "attendance_tracker_${input}" ]; then
        echo "Error: Directory 'attendance_tracker_${input}' already exists."
        read -p "Do you want to overwrite it? (y/n): " overwrite
        if [ "$overwrite" = "y" ] || [ "$overwrite" = "Y" ]; then
            rm -rf "attendance_tracker_${input}"
            echo "Existing directory removed."
            break
        else
            echo "Please choose a different directory name."
            continue
        fi
    fi
    
    break
done

# Create the main directory
mkdir -p "attendance_tracker_${input}"

# Create Helpers directory
mkdir -p "attendance_tracker_${input}/Helpers"

# Create and populate assets.csv with data
cat > "attendance_tracker_${input}/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
griphen@example.com,Griphen Mweene,14,13
EOF

# Create and populate config.json with configuration
cat > "attendance_tracker_${input}/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

# Create reports directory
mkdir -p "attendance_tracker_${input}/reports"

# Create and populate reports.log with initial log data
cat > "attendance_tracker_${input}/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

# Write the Python code to attendance_checker.py
cat > "attendance_tracker_${input}/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100
            
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

echo "Directory structure created successfully!"
echo "Created: attendance_tracker_${input}/"
echo "All files have been populated with their respective data."
echo ""

# Prompt user to update thresholds with validation
while true; do
    read -p "Do you want to update the attendance thresholds? (y/n): " update_threshold
    
    # Check if input is empty
    if [ -z "$update_threshold" ]; then
        echo "Error: Input cannot be empty. Please enter 'y' for Yes or 'n' for No."
        continue
    fi
    
    # Validate input - only accept y, Y, n, or N
    if [ "$update_threshold" = "y" ] || [ "$update_threshold" = "Y" ]; then
        break
    elif [ "$update_threshold" = "n" ] || [ "$update_threshold" = "N" ]; then
        break
    else
        echo "Error: Invalid input '$update_threshold'. Please enter 'y' for Yes or 'n' for No."
    fi
done

if [ "$update_threshold" = "y" ] || [ "$update_threshold" = "Y" ]; then
    # Validate Warning threshold
    while true; do
        read -p "Enter new Warning threshold (default 75, press Enter to skip): " warning_value
        
        # If empty, use default
        if [ -z "$warning_value" ]; then
            warning_value=75
            echo "Using default Warning threshold: 75%"
            break
        fi
        
        # Check if input is a valid number
        if [[ "$warning_value" =~ ^[0-9]+$ ]]; then
            if [ "$warning_value" -ge 0 ] && [ "$warning_value" -le 100 ]; then
                break
            else
                echo "Error: Warning threshold must be between 0 and 100."
            fi
        else
            echo "Error: Please enter a valid number."
        fi
    done
    
    # Validate Failure threshold
    while true; do
        read -p "Enter new Failure threshold (default 50, press Enter to skip): " failure_value
        
        # If empty, use default
        if [ -z "$failure_value" ]; then
            failure_value=50
            echo "Using default Failure threshold: 50%"
            break
        fi
        
        # Check if input is a valid number
        if [[ "$failure_value" =~ ^[0-9]+$ ]]; then
            if [ "$failure_value" -ge 0 ] && [ "$failure_value" -le 100 ]; then
                # Check if failure threshold is less than warning threshold
                if [ "$failure_value" -lt "$warning_value" ]; then
                    break
                else
                    echo "Error: Failure threshold ($failure_value) must be less than Warning threshold ($warning_value)."
                fi
            else
                echo "Error: Failure threshold must be between 0 and 100."
            fi
        else
            echo "Error: Please enter a valid number."
        fi
    done
    
    # Use sed to update config.json in-place
    sed -i "s/\"warning\": [0-9]*/\"warning\": $warning_value/" "attendance_tracker_${input}/Helpers/config.json"
    sed -i "s/\"failure\": [0-9]*/\"failure\": $failure_value/" "attendance_tracker_${input}/Helpers/config.json"
    
    echo "Thresholds updated: Warning=$warning_value%, Failure=$failure_value%"
else
    echo "Thresholds not updated. Using defaults: Warning=75%, Failure=50%"
fi

echo ""
echo "========================================="
echo "Performing Health Check..."
echo "========================================="

# Check if python3 is installed
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version)
    echo "✓ SUCCESS: Python3 is installed - $python_version"
else
    echo "✗ WARNING: Python3 is not installed on this system"
    echo "  Please install Python3 to run the attendance checker"
fi

echo ""
echo "Verifying directory structure..."

# Verify directory structure
structure_valid=true

# Check main directory
if [ -d "attendance_tracker_${input}" ]; then
    echo "✓ Main directory: attendance_tracker_${input}"
else
    echo "✗ Main directory missing"
    structure_valid=false
fi

# Check attendance_checker.py
if [ -f "attendance_tracker_${input}/attendance_checker.py" ]; then
    echo "✓ File exists: attendance_checker.py"
else
    echo "✗ File missing: attendance_checker.py"
    structure_valid=false
fi

# Check Helpers directory and files
if [ -d "attendance_tracker_${input}/Helpers" ]; then
    echo "✓ Directory exists: Helpers/"
    
    if [ -f "attendance_tracker_${input}/Helpers/assets.csv" ]; then
        echo "  ✓ File exists: Helpers/assets.csv"
    else
        echo "  ✗ File missing: Helpers/assets.csv"
        structure_valid=false
    fi
    
    if [ -f "attendance_tracker_${input}/Helpers/config.json" ]; then
        echo "  ✓ File exists: Helpers/config.json"
    else
        echo "  ✗ File missing: Helpers/config.json"
        structure_valid=false
    fi
else
    echo "✗ Directory missing: Helpers/"
    structure_valid=false
fi

# Check reports directory and file
if [ -d "attendance_tracker_${input}/reports" ]; then
    echo "✓ Directory exists: reports/"
    
    if [ -f "attendance_tracker_${input}/reports/reports.log" ]; then
        echo "  ✓ File exists: reports/reports.log"
    else
        echo "  ✗ File missing: reports/reports.log"
        structure_valid=false
    fi
else
    echo "✗ Directory missing: reports/"
    structure_valid=false
fi

echo ""
echo "========================================="
if [ "$structure_valid" = true ]; then
    echo "✓ Health Check PASSED!"
    echo "========================================="
    echo ""
    echo "Project setup complete!"
    echo "You can now run the attendance checker by navigating to:"
    echo "  cd attendance_tracker_${input}"
    echo "  python3 attendance_checker.py"
else
    echo "✗ Health Check FAILED!"
    echo "========================================="
    echo "Some files or directories are missing."
fi
