#!/bin/bash

# Define variables
EVILGOPHISH_DIR="/opt/evilgophish"
DB_NAME="evilgophish"
DB_USER="evilgophishuser"
DB_PASS="your_password"
ROOT_DOMAIN="example.com"
SUBDOMAINS="accounts myaccount"
ROOT_DOMAIN_BOOL="false"
FEED_BOOL="true"
RID_REPLACEMENT="user_id"

# Update and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y git python3 python3-pip postgresql postgresql-contrib python3-venv

# Clone EvilGophish repository if it doesn't exist
if [ ! -d "$EVILGOPHISH_DIR" ]; then
    echo "Cloning EvilGophish repository..."
    git clone https://github.com/fin3ss3g0d/evilgophish.git "$EVILGOPHISH_DIR"
else
    echo "Directory $EVILGOPHISH_DIR already exists. Skipping clone."
fi

# Change to EvilGophish directory
cd "$EVILGOPHISH_DIR" || { echo "Failed to change directory to $EVILGOPHISH_DIR. Exiting."; exit 1; }

# Create a Python virtual environment and install dependencies
echo "Creating Python virtual environment and installing dependencies..."
python3 -m venv venv
source venv/bin/activate

if [ -f requirements.txt ]; then
    pip install -r requirements.txt
else
    echo "requirements.txt not found. Please ensure you have the necessary dependencies."
fi

# Setup PostgreSQL
echo "Setting up PostgreSQL..."
sudo service postgresql start
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Run EvilGophish setup script
echo "Running EvilGophish setup script..."
./setup.sh "$ROOT_DOMAIN" "$SUBDOMAINS" "$ROOT_DOMAIN_BOOL" "$FEED_BOOL" "$RID_REPLACEMENT"

# Check for the main entry point
echo "Locating the main entry point for EvilGophish..."
if [ -f evilfeed ]; then
    ENTRY_POINT="evilfeed"
else
    echo "Main entry point for EvilGophish not found. Please manually identify the correct start script or binary."
    exit 1
fi

# Create a start script for EvilGophish
echo "Creating a start script for EvilGophish..."
cat <<EOL | sudo tee /opt/evilgophish/start_evilgophish.sh
#!/bin/bash
cd /opt/evilgophish
source venv/bin/activate
./$ENTRY_POINT
EOL

sudo chmod +x /opt/evilgophish/start_evilgophish.sh

echo "EvilGophish installation and setup completed. You can start EvilGophish using /opt/evilgophish/start_evilgophish.sh"
