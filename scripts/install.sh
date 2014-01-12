#!/bin/sh

echo "###"
echo "Welcome to the Oxypanel Installer"
echo "###"

# Enable job control
set -m

# Dependency install
if which yum > /dev/null; then
    printf "[1] Installing yum packages..."
    yum install libpcre3 libpcre3-dev libpcre++-dev libreadline6 libreadline6-dev openssl libssl-dev gcc gcc-c++ python cmake git -y > /dev/null
else
    printf "[1] Installing apt packages..."
    apt-get install libpcre3 libpcre3-dev libpcre++-dev libreadline6 libreadline6-dev openssl libssl-dev build-essential python cmake git -y > /dev/null
fi
echo " complete"

# Download install files
printf "[2] Downloading all files..."
wget http://cachefly.cachefly.net/10mb.test -O /tmp/test1 --quiet &
wget http://cachefly.cachefly.net/10mb.test -O /tmp/test2 --quiet &
wget http://cachefly.cachefly.net/10mb.test -O /tmp/test3 --quiet &

# Wait for the downloads
while [ 1 ]; do fg > /dev/null 2>&1; [ $? == 1 ] && break; done
echo " complete"


# Start installing