#!/bin/bash
clear

echo " --- starting build --- "
echo ""

# Create venv if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate venv
source venv/bin/activate

echo " --- starting local environment --- "
echo "! linux start build !"
echo ""

# Check if Flask is installed; install it if it's not
if ! python -c "import flask" &> /dev/null; then
    echo "Flask not found. Installing Flask..."
    pip install Flask
else
    echo "Flask is already installed."
fi

# Run your Python app
python3 main.py

# Deactivate venv
deactivate

echo ""
echo " !environment stopped! "
echo " --- build successful --- "
