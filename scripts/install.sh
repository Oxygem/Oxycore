#!/bin/sh

# Configure paths
OXYPANEL_PATH="/opt/oxypanel"

# Configure versions
LUAJIT_VERSION="2.0.2"
LUACJSON_VERSION="2.1.0"
NGINX_VERSION="1.4.4"
NGINXLUA_VERSION="0.9.5rc2"
NGINXDEV_VERSION="0.2.19"
NODE_VERSION="0.10.24"
MARIADB_VERSION="5.5.36"
ELASTICSEARCH_VERSION="1.0.1"


echo ""
echo "###"
echo "Welcome to the Oxypanel Installer"
echo "###"
echo ""

# Exit on errors
set -e
# Path
export PATH=$PATH:$OXYPANEL_PATH/bin:$OXYPANEL_PATH/sbin
# Log path
LOG_PATH=$( pwd )

# Dependency install/check
if which yum > /dev/null; then
    prinf "[1] Updating & installing yum packages..."
    yum install NEED_TO_GET_YUM_LIST_SORTED -y >> $LOG_PATH/install.log
elif which apt-get > /dev/null; then
    echo "[1] Updating & installing apt packages..."
    apt-get update >> $LOG_PATH/install.log
    apt-get install libpcre3 libpcre3-dev libpcre++-dev libreadline6 libreadline6-dev openssl libssl-dev libncurses5-dev build-essential python cmake git -y >> $LOG_PATH/install.log 2>&1
else
    echo "No yum or apt detected, exiting..."
    echo "This script only supports OS's with yum/apt installed"
    echo "Please visit http://doc.oxypanel.com/Install for a manual/generic install guide"
    echo "Alternatively just cat this bash script, and run through it manually"
    exit 1
fi


# Download install files
#function download() {
#    printf "    LuaJIT $LUAJIT_VERSION... "
#    find /tmp/luajit.tar.gz > /dev/null 2>&1 || wget "http://luajit.org/download/LuaJIT-$LUAJIT_VERSION.tar.gz" -O /tmp/luajit.tar.gz -a $LOG_PATH/install.log
#    echo "complete"
#}

echo "[2] Downloading files..."
printf "    LuaJIT $LUAJIT_VERSION... "
find /tmp/luajit.tar.gz > /dev/null 2>&1 || wget "http://luajit.org/download/LuaJIT-$LUAJIT_VERSION.tar.gz" -O /tmp/luajit.tar.gz -a $LOG_PATH/install.log
echo "complete"
printf "    LuaCJSON $LUACJSON_VERSION... "
find /tmp/luacjson.tar.gz > /dev/null 2>&1 || wget "http://www.kyne.com.au/~mark/software/download/lua-cjson-$LUACJSON_VERSION.tar.gz" -O /tmp/luacjson.tar.gz -a $LOG_PATH/install.log
echo "complete"
printf "    Nginx $NGINX_VERSION... "
find /tmp/nginx.tar.gz > /dev/null 2>&1 || wget "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" -O /tmp/nginx.tar.gz -a $LOG_PATH/install.log
echo "complete"
printf "    Nginx-Lua $NGINXLUA_VERSION... "
find /tmp/nginxlua.tar.gz > /dev/null 2>&1 || wget "https://github.com/chaoslawful/lua-nginx-module/archive/v$NGINXLUA_VERSION.tar.gz" -O /tmp/nginxlua.tar.gz -a $LOG_PATH/install.log
echo "complete"
printf "    Nginx-Devel $NGINXDEV_VERSION... "
find /tmp/nginxdev.tar.gz > /dev/null 2>&1 || wget "https://github.com/simpl/ngx_devel_kit/archive/v$NGINXDEV_VERSION.tar.gz" -O /tmp/nginxdev.tar.gz -a $LOG_PATH/install.log
echo "complete"
printf "    Node $NODE_VERSION... "
find /tmp/node.tar.gz > /dev/null 2>&1 || wget "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz" -O /tmp/node.tar.gz -a $LOG_PATH/install.log
echo "complete"
printf "    MariaDB $MARIADB_VERSION... "
find /tmp/mariadb.tar.gz > /dev/null 2>&1 || wget "http://mirrors.coreix.net/mariadb/mariadb-$MARIADB_VERSION/kvm-tarbake-jaunty-x86/mariadb-$MARIADB_VERSION.tar.gz" -O /tmp/mariadb.tar.gz -a $LOG_PATH/install.log
echo "complete"

# Untar files
echo "[3] Untarring files... "
tar -xf /tmp/luajit.tar.gz -C /tmp
tar -xf /tmp/luacjson.tar.gz -C /tmp
tar -xf /tmp/nginx.tar.gz -C /tmp
tar -xf /tmp/nginxlua.tar.gz -C /tmp
tar -xf /tmp/nginxdev.tar.gz -C /tmp
tar -xf /tmp/node.tar.gz -C /tmp
tar -xf /tmp/mariadb.tar.gz -C /tmp

# Setup directory
mkdir -p "$OXYPANEL_PATH/src" >> $LOG_PATH/install.log

# Start installing
echo "[4] Compiling & installing..."
printf "    LuaJIT/LuaCJSON... "
cd /tmp/LuaJIT*
make >> $LOG_PATH/install.log 2>&1
make install PREFIX=$OXYPANEL_PATH >> $LOG_PATH/install.log
cd /tmp/lua-cjson*
make PREFIX=$OXYPANEL_PATH LUA_INCLUDE_DIR=$OXYPANEL_PATH/include/luajit-2.0 >> $LOG_PATH/install.log 2>&1
make install PREFIX=$OXYPANEL_PATH >> $LOG_PATH/install.log
echo "complete"

printf "    Nginx... "
cd /tmp/nginx-*
export LUAJIT_INC="$OXYPANEL_PATH/include/luajit-2.0"
export LUAJIT_LIB="$OXYPANEL_PATH/lib"
./configure --prefix=$OXYPANEL_PATH --with-http_ssl_module --add-module=../ngx_devel_kit* --add-module=../lua-nginx-module* >> $LOG_PATH/install.log
make >> $LOG_PATH/install.log 2>&1
make install >> $LOG_PATH/install.log
echo "complete"

printf "    Node... "
cd /tmp/node-*
./configure --prefix=$OXYPANEL_PATH >> $LOG_PATH/install.log
make >> $LOG_PATH/install.log 2>&1
make install >> $LOG_PATH/install.log
echo "complete"

printf "    MariaDB... "
cd /tmp/mariadb*
cmake -DCMAKE_INSTALL_PREFIX:PATH=$OXYPANEL_PATH . >> $LOG_PATH/install.log 2>&1
make >> $LOG_PATH/install.log 2>&1
make install >> $LOG_PATH/install.log
echo "complete"

echo "[8] Cloning Oxypanel GitHub repo"
( cd $OXYPANEL_PATH/src/ && git status > /dev/null 2>&1 ) || git clone https://github.com/Oxygem/Oxypanel.git $OXYPANEL_PATH/src >> $LOG_PATH/install.log


echo "[9] Creating SSH key"


echo "[10] Generating secret keys"


echo "[11] Copying config example"
find $OXYPANEL_PATH/src/config.lua > /dev/null 2>&1 || cp $OXYPANEL_PATH/src/scripts/config.example.lua $OXYPANEL_PATH/src/config.lua

echo "[12] Importing database structure"
#cat $OXYPANEL_PATH/src/scripts/layout.sql

echo "[13] Running build script"
#cd $OXYPANEL_PATH/src
cd $OXYPANEL_PATH/src/ && $OXYPANEL_PATH/bin/luajit scripts/build.lua >> $LOG_PATH/install.log

# Setup path env
touch /root/.profile
echo 'export PATH=$PATH:'"$OXYPANEL_PATH/bin:$OXYPANEL_PATH/sbin" >> /root/.profile
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'"$OXYPANEL_PATH/lib" >> /root/.profile

# Hacky fix!
mkdir -p /usr/local/lib/lua/5.1/
ln -s $OXYPANEL_PATH/lib/lua/5.1/cjson.so /usr/local/lib/lua/5.1/cjson.so

# Done!
echo ""
echo "###"
echo "Oxypanel Install Complete"
echo "###"
echo ""
exit 0