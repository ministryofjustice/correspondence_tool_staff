set -e
set -o pipefail

sudo apt-get update
sudo apt-get --assume-yes install python3-pip
sudo pip3 install awscli
echo 'AWS CLI installed successfully'