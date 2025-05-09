#!/bin/bash

# Ensure the script is run with root privileges for system installs
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)."
   exit 1
fi

clear

echo " --- starting build --- "
echo ""

# Update package lists and install system dependencies
echo "Installing system packages: nginx, python3-venv, python3-pip..."
apt update && apt install -y nginx python3-venv python3-pip

# Create venv if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate venv
echo "Activating virtual environment..."
source venv/bin/activate

echo " --- starting local environment --- "
echo "! linux start build !"
echo ""

# Install Gunicorn and Flask in the venv
pip install --upgrade pip
if ! python -c "import flask" &> /dev/null; then
    echo "Flask not found in venv. Installing Flask..."
    pip install Flask
else
    echo "Flask is already installed in venv."
fi

if ! python -c "import gunicorn" &> /dev/null; then
    echo "Gunicorn not found in venv. Installing Gunicorn..."
    pip install gunicorn
else
    echo "Gunicorn is already installed in venv."
fi

# Optional: install other dependencies from requirements.txt
if [ -f "requirements.txt" ]; then
    echo "Installing project dependencies from requirements.txt..."
    pip install -r requirements.txt
fi

# Ensure nginx service is running
echo "Starting and enabling nginx..."
systemctl enable nginx
systemctl restart nginx

# Run your Flask app with Gunicorn
# Adjust app module/path as needed (here: main:app)
echo "Launching Flask app with Gunicorn..."
# Use exec so Gunicorn replaces the shell process
exec gunicorn -w 4 -b 127.0.0.1:8000 main:app

# Deactivate venv (this line won't be reached because of exec)
deactivate

echo ""
echo " !environment stopped! "
echo " --- build successful --- "
