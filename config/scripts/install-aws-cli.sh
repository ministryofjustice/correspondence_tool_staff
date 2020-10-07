set -e

apt-get update
apt-get --assume-yes install python3-pip
pip3 install awscli
echo 'AWS CLI installed successfully'