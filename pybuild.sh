#!/bin/bash
# 
set -e  # Exit on error
clear

echo " --- Starting build ---"
echo ""

# Ensure script is run from the directory containing main.py
if [ ! -f "main.py" ]; then
    echo "Error: main.py not found in current directory."
    exit 1
fi

# Check if nginx is installed
if ! command -v nginx >/dev/null 2>&1; then
    echo "Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
else
    echo "Nginx is already installed."
fi

# Enable and start nginx
echo "Enabling and starting Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
else
    echo "Virtual environment already exists."
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Check for required Python packages
REQUIRED_PACKAGES=("Flask" "gunicorn")
echo "Checking Python dependencies..."
for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! pip show "$package" > /dev/null 2>&1; then
        echo "Installing $package..."
        pip install "$package"
    else
        echo "$package is already installed."
    fi
done

# Create systemd service for Gunicorn (if it doesn't exist)
SERVICE_FILE=/etc/systemd/system/myflaskapp.service
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Creating systemd service for Gunicorn..."
    sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/gunicorn -w 4 -b 127.0.0.1:8000 main:app

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable myflaskapp
    sudo systemctl start myflaskapp
else
    echo "Gunicorn systemd service already exists."
fi

# Configure Nginx to reverse proxy to Gunicorn
NGINX_CONF="/etc/nginx/sites-available/myflaskapp"
if [ ! -f "$NGINX_CONF" ]; then
    echo "Creating Nginx configuration..."
    sudo bash -c "cat > $NGINX_CONF" <<EOF
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    sudo ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo systemctl restart nginx
else
    echo "Nginx configuration already exists."
fi

echo ""
echo " --- Environment started successfully ---"
echo "Your Flask app is accessible at: http://localhost or your server's IP"
