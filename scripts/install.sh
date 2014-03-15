#!/bin/sh

# Configure paths
OXYPANEL_PATH="/opt/oxypanel"

# Configure to-compile versions
LUAJIT_VERSION="2.0.2"
LUACJSON_VERSION="2.1.0"
NGINX_VERSION="1.4.4"
NGINXLUA_VERSION="0.9.5rc2"
NGINXDEV_VERSION="0.2.19"
NODE_VERSION="0.10.24"

# Configure package version
MARIADB_VERSION="5.5"
ELASTICSEARCH_VERSION="1.0.1"

# Packages
APT_PACKAGES="mariadb-server libpcre3 libpcre3-dev libpcre++-dev libreadline6 libreadline6-dev openssl libssl-dev libncurses5-dev build-essential python make git wget"
YUM_PACKAGES="MariaDB-server pcre-devel openssl-devel g++ make wget git python"


# Exit on errors
set -e
# Path
export PATH=$PATH:$OXYPANEL_PATH/bin:$OXYPANEL_PATH/sbin
# Log path
LOG_PATH=$( pwd )



# Lets go
echo ""
echo "###"
echo "Welcome to the Oxypanel Installer"
echo "###"
echo ""

# Work out OS
OS_NAME=$( head -n 1 /etc/issue 2> /dev/null | grep -oEi '[a-zA-Z/]+' | head -n 1 )
OS_VERSION=$( head -n 1 /etc/issue 2> /dev/null | grep -oEi '[0-9]' | head -n 1 ) # major version only

# OS details needed for MariaDB repositories
# arch/version only needed on CentOS, will fail @ yum
if [ "$OS_NAME" = "" ]; then
    echo "[Error]: Could not detect OS"
    echo ""
    echo "This script only supports Debian, Ubuntu & CentOS"
    echo "Please visit http://doc.oxypanel.com/Install for a manual/generic install guide"
    echo "Alternatively just cat this bash script, and run through it manually"
    echo ""
    exit 1
fi

echo "OS Detected: $OS_NAME $OS_VERSION"
echo ""


# Debian/Ubuntu - apt
if [ "$OS_NAME" = "Debian" ] || [ "$OS_NAME" = "Ubuntu" ]; then
    echo "[1] Preparing apt"
    apt-get update >> $LOG_PATH/install.log

    # Insane, thanks ubu/deb
    if [ "$OS_NAME" = "Debian" ]; then
        apt-get install python-software-properties -y >> $LOG_PATH/install.log
        apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db >> $LOG_PATH/install.log 2>&1
        add-apt-repository "http://mirrors.coreix.net/mariadb/repo/$MARIADB_VERSION/debian" >> $LOG_PATH/install.log
    else
        apt-get install software-properties-common -y >> $LOG_PATH/install.log
        apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db >> $LOG_PATH/install.log 2>&1
        add-apt-repository "http://mirrors.coreix.net/mariadb/repo/$MARIADB_VERSION/ubuntu" >> $LOG_PATH/install.log
    fi
    apt-get update >> $LOG_PATH/install.log

    echo "[2] Updating & installing apt packages"
    DEBIAN_FRONTEND=noninteractive apt-get install $APT_PACKAGES -y >> $LOG_PATH/install.log
fi

# CentOS - yum
if [ "$OS_NAME" = "CentOS" ]; then
    # Check we have OS_VERSION as needed
    if [ "$OS_VERSION" = "" ]; then
        echo "[Error]: Arch not detected, required for CentOS yum config"
        exit 1
    fi

    echo "[1] Preparing yum"
    rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB >> $LOG_PATH/install.log
    FILE="/etc/yum.repos.d/MariaDB.repo"
    touch $FILE
    echo "[mariadb]" > $FILE
    echo "name = MariaDB" >> $FILE
    echo "baseurl = http://yum.mariadb.org/$MARIADB_VERSION/centos$OS_VERSION-x86" >> $FILE
    echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> $FILE
    echo "gpgcheck=1" >> $FILE

    echo "[2] Updating & installing yum packages"
    # postfix is borked w/ mariadb in centos6
    rpm -e --nodeps mysql-libs 2> /dev/null || true # http://blog.johannes-beck.name/?p=199
    yum install $YUM_PACKAGES -y >> $LOG_PATH/install.log
fi


# Download install files
echo "[3] Downloading files"
# LuaJIT+CJSON
if [ ! $( which luajit 2> /dev/null ) ]; then
    printf "    LuaJIT $LUAJIT_VERSION... "
    find /tmp/luajit.tar.gz > /dev/null 2>&1 || wget "http://luajit.org/download/LuaJIT-$LUAJIT_VERSION.tar.gz" -O /tmp/luajit.tar.gz -a $LOG_PATH/install.log
    echo "complete"
    printf "    LuaCJSON $LUACJSON_VERSION... "
    find /tmp/luacjson.tar.gz > /dev/null 2>&1 || wget "http://www.kyne.com.au/~mark/software/download/lua-cjson-$LUACJSON_VERSION.tar.gz" -O /tmp/luacjson.tar.gz -a $LOG_PATH/install.log
    echo "complete"
fi
# Nginx+DevelKit+Lua
if [ ! $( which nginx 2> /dev/null ) ]; then
    printf "    Nginx $NGINX_VERSION... "
    find /tmp/nginx.tar.gz > /dev/null 2>&1 || wget "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" -O /tmp/nginx.tar.gz -a $LOG_PATH/install.log
    echo "complete"
    printf "    Nginx-Lua $NGINXLUA_VERSION... "
    find /tmp/nginxlua.tar.gz > /dev/null 2>&1 || wget "https://github.com/chaoslawful/lua-nginx-module/archive/v$NGINXLUA_VERSION.tar.gz" -O /tmp/nginxlua.tar.gz -a $LOG_PATH/install.log
    echo "complete"
    printf "    Nginx-Devel $NGINXDEV_VERSION... "
    find /tmp/nginxdev.tar.gz > /dev/null 2>&1 || wget "https://github.com/simpl/ngx_devel_kit/archive/v$NGINXDEV_VERSION.tar.gz" -O /tmp/nginxdev.tar.gz -a $LOG_PATH/install.log
    echo "complete"
fi
# Node
if [ ! $( which node 2> /dev/null ) ] || [ ! $( which npm ) ]; then
    printf "    Node $NODE_VERSION... "
    find /tmp/node.tar.gz > /dev/null 2>&1 || wget "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz" -O /tmp/node.tar.gz -a $LOG_PATH/install.log
    echo "complete"
fi


# Untar files
echo "[4] Untarring files"
find /tmp/*.tar.gz | xargs -i tar -C /tmp/ -xf {}

# Setup directory
mkdir -p "$OXYPANEL_PATH/src"


# Start installing
echo "[5] Compiling & installing"
# LuaJIT+CJSON
if [ ! $( which luajit 2> /dev/null ) ]; then
    printf "    LuaJIT/LuaCJSON... "
    cd /tmp/LuaJIT*
    make >> $LOG_PATH/install.log
    make install PREFIX=$OXYPANEL_PATH >> $LOG_PATH/install.log
    cd /tmp/lua-cjson*
    make -w PREFIX=$OXYPANEL_PATH LUA_INCLUDE_DIR=$OXYPANEL_PATH/include/luajit-2.0 >> $LOG_PATH/install.log
    make install PREFIX=$OXYPANEL_PATH >> $LOG_PATH/install.log
    echo "complete"
fi
# Nginx+DevelKit+Lua
if [ ! $( which nginx 2> /dev/null ) ]; then
    printf "    Nginx... "
    cd /tmp/nginx-*
    export LUAJIT_INC="$OXYPANEL_PATH/include/luajit-2.0"
    export LUAJIT_LIB="$OXYPANEL_PATH/lib"
    ./configure --prefix=$OXYPANEL_PATH --with-http_ssl_module --add-module=../ngx_devel_kit* --add-module=../lua-nginx-module* >> $LOG_PATH/install.log
    make -w >> $LOG_PATH/install.log
    make install >> $LOG_PATH/install.log
    echo "complete"
fi
# Node
if [ ! $( which node 2> /dev/null ) ]; then
    printf "    Node... "
    cd /tmp/node-*
    ./configure --prefix=$OXYPANEL_PATH >> $LOG_PATH/install.log
    make -w >> $LOG_PATH/install.log
    make install >> $LOG_PATH/install.log
    echo "complete"
fi


echo "[6] Cloning Oxypanel & Luawa GitHub repos"
cd $OXYPANEL_PATH/src/
git status > /dev/null 2>&1 || git clone https://github.com/Oxygem/Oxypanel.git $OXYPANEL_PATH/src >> $LOG_PATH/install.log
git submodule update --init --recursive >> $LOG_PATH/install.log

echo "[7] Creating SSH key"


echo "[8] Generating secret keys"


echo "[9] Copying config example"
find $OXYPANEL_PATH/src/config.lua > /dev/null 2>&1 || cp $OXYPANEL_PATH/src/scripts/config.example.lua $OXYPANEL_PATH/src/config.lua

echo "[10] Importing database structure"
#cat $OXYPANEL_PATH/src/scripts/layout.sql

echo "[11] Running build script"
#cd $OXYPANEL_PATH/src
cd $OXYPANEL_PATH/src/ && $OXYPANEL_PATH/bin/luajit scripts/build.lua >> $LOG_PATH/install.log

# Setup path env
echo "[12] Setting up paths, linking"
touch /root/.bash_profile
echo 'export PATH=$PATH:'"$OXYPANEL_PATH/bin:$OXYPANEL_PATH/sbin" >> /root/.bash_profile
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'"$OXYPANEL_PATH/lib" >> /root/.bash_profile
# Hacky fix!
mkdir -p /usr/local/lib/lua/5.1/
find /usr/local/lib/lua/5.1/cjson.so > /dev/null 2>&1 || ln -s $OXYPANEL_PATH/lib/lua/5.1/cjson.so /usr/local/lib/lua/5.1/cjson.so


# Done!
echo ""
echo "###"
echo "Oxypanel Install Complete"
echo "###"
echo ""
exit 0