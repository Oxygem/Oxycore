#!/bin/sh

# Configure paths
OXYPANEL_PATH="/opt/oxypanel"

# Configure versions
LUAJIT_VERSION="2.0.2"
LUACJSON_VERSION="2.1.0"
NGINX_VERSION="1.4.4"
NGINXLUA_VERSION="0.9.4"
NGINXDEV_VERSION="0.2.19"
NODE_VERSION="0.10.24"

echo ""
echo "###"
echo "Welcome to the Oxypanel Installer"
echo "###"
echo ""

# Enable job control
set -m


# Dependency install/check
if which yum > /dev/null; then
    prinf "[1] Updating & installing yum packages..."
    yum update >> install.log
    yum install NEED_TO_GET_YUM_LIST_SORTED -y >> install.log
elif which apt-get > /dev/null; then
    echo "[1] Updating & installing apt packages..."
    apt-get update >> install.log
    apt-get install libpcre3 libpcre3-dev libpcre++-dev libreadline6 libreadline6-dev openssl libssl-dev build-essential python cmake git -y >> install.log
else
    echo "No yum or apt detected, exiting..."
    echo "This script only supports OS's with yum/apt installed"
    echo "Please visit http://doc.oxypanel.com/Install for a manual/generic install guide"
    exit 1
fi


# Download install files
echo "[2] Downloading files..."
printf "    LuaJIT $LUAJIT_VERSION... "
wget "http://luajit.org/download/LuaJIT-$LUAJIT_VERSION.tar.gz" -O /tmp/luajit.tar.gz --quiet
echo "complete"
printf "    LuaCJSON $LUACJSON_VERSION... "
wget "http://www.kyne.com.au/~mark/software/download/lua-cjson-$LUACJSON_VERSION.tar.gz" -O /tmp/luacjson.tar.gz --quiet
echo "complete"
printf "    Nginx $NGINX_VERSION... "
wget "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" -O /tmp/nginx.tar.gz --quiet
echo "complete"
printf "    Nginx-Lua $NGINXLUA_VERSION... "
wget "https://github.com/chaoslawful/lua-nginx-module/archive/v$NGINXLUA_VERSION.tar.gz" -O /tmp/nginxlua.tar.gz --quiet
echo "complete"
printf "    Nginx-Devel $NGINXDEV_VERSION... "
wget "https://github.com/simpl/ngx_devel_kit/archive/v$NGINXDEV_VERSION.tar.gz" -O /tmp/nginxdev.tar.gz --quiet
echo "complete"
printf "    Node $NODE_VERSION... "
wget "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz" -O /tmp/node.tar.gz --quiet
echo "complete"

# Untar files
echo "[3] Untarring files... "
tar -xf /tmp/*.tar.gz -C /tmp


# Setup user
echo "[3] Add oxypanel user..."
echo "### If prompted please use a strong password, you do not need to remember it"
adduser oxypanel --home $OXYPANEL_PATH >> install.log
mkdir -p "$OXYPANEL_PATH/src" >> install.log


# Start installing
echo "[4] Compiling & installing LuaJIT & LuaCJSON..."
cd /tmp/LuaJIT*
make clean >> install.log
make >> install.log
make install PREFIX=$OXYPANEL_PATH >> install.log
cd /tmp/lua-cjson*
make clean >> install.log
make PREFIX=$OXYPANEL_PATH LUA_INCLUDE_DIR=$OXYPANEL_PATH/include/luajit-2.0 >> install.log
make install PREFIX=$OXYPANEL_PATH >> install.log

echo "[5] Compiling & installing Nginx..."
cd /tmp/nginx-*
export LUAJIT_INC="$OXYPANEL_PATH/include/luajit-2.0"
export LUAJIT_LIB="$OXYPANEL_PATH/lib"
make clean >> install.log
./configure --prefix=$OXYPANEL_PATH --with-http_ssl_module --add-module=../ngx_devel_kit* --add-module=../lua-nginx-module* >> install.log
make >> install.log
make install >> install.log

echo "[6] Compiling & installing Node..."
cd /tmp/node-*
make clean >> install.log
./configure --prefix=$OXYPANEL_PATH >> install.log
make >> install.log
make install >> install.log

echo "[7] Installing MariaDB..."


echo "[8] Preparing Oxypanel..."


echo "### setup SSH key"


echo "### general secret keys"


echo "### clone git repo"
git clone https://github.com/Oxygem/Oxypanel.git $OXYPANEL_PATH/src >> install.log

echo "### copy config example"
cp $OXYPANEL_PATH/src/config.example.lua $OXYPANEL_PATH/src/config.lua

echo "### import database structure"
cat $OXYPANEL_PATH/src/scripts/layout.sql

echo "### build scripts"
cd $OXYPANEL_PATH/src
$OXYPANEL_PATH/bin/luajit scripts/build.lua >> install.log


# Done!
echo ""
echo "###"
echo "Oxypanel Install Complete"
echo "###"
echo ""
exit 0