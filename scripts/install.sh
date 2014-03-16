#!/usr/bin/env sh

# Oxypanel
# File: scripts/install.sh
# Desc: install Oxypanel
#       Although there is some protection, assume running this on a running Oxypanel node = death
#       Assumes 2 cores/cpus available (make & nginx conf)
#       Use: curl -fSsL https://raw.github.com/Oxygem/Oxypanel/master/scripts/install.sh | bash
#       Safe Use: download above file, confirm acceptable contents & run



###################################################### Config
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
APT_PACKAGES="mariadb-server mariadb-client libpcre3 libpcre3-dev libpcre++-dev libreadline6 libreadline6-dev openssl libssl-dev libncurses5-dev build-essential python make git wget"
YUM_PACKAGES="MariaDB-server MariaDB-client pcre-devel openssl-devel g++ make wget git python"



###################################################### Setup
# Exit on errors
set -e
# Show commands
if [ "$1" = "debug" ]; then
    set -x
fi
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



###################################################### Install: prepare
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
    if ! cat /etc/apt/sources.list 2> /dev/null | grep mariadb > /dev/null; then
        apt-get update >> $LOG_PATH/install.log

        # Insane, thanks ubu/deb
        add_repo() {
            apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db >> $LOG_PATH/install.log 2>&1
            add-apt-repository "http://mirrors.coreix.net/mariadb/repo/$MARIADB_VERSION/$1" >> $LOG_PATH/install.log
        }
        if [ "$OS_NAME" = "Debian" ]; then
            apt-get install python-software-properties -y >> $LOG_PATH/install.log 2>&1
            add_repo "debian"
        else
            apt-get install software-properties-common -y >> $LOG_PATH/install.log 2>&1
            add_repo "ubuntu"
        fi
    fi
    apt-get update >> $LOG_PATH/install.log

    echo "[2] Updating & installing apt packages"
    DEBIAN_FRONTEND=noninteractive apt-get install $APT_PACKAGES -y >> $LOG_PATH/install.log 2>&1
fi

# CentOS - yum
if [ "$OS_NAME" = "CentOS" ]; then
    # Check we have OS_VERSION as needed
    if [ "$OS_VERSION" = "" ]; then
        echo "[Error]: Arch not detected, required for CentOS yum config"
        exit 1
    fi

    echo "[1] Preparing yum"
    if ! find /etc/yum.repos.d/MariaDB.repo > /dev/null 2>&1; then
        rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB >> $LOG_PATH/install.log
        FILE="/etc/yum.repos.d/MariaDB.repo"
        touch $FILE
        echo "[mariadb]" > $FILE
        echo "name = MariaDB" >> $FILE
        echo "baseurl = http://yum.mariadb.org/$MARIADB_VERSION/centos$OS_VERSION-x86" >> $FILE
        echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> $FILE
        echo "gpgcheck=1" >> $FILE
    fi

    echo "[2] Updating & installing yum packages"
    # postfix is borked w/ mariadb in centos6
    rpm -e --nodeps mysql-libs 2> /dev/null || true # http://blog.johannes-beck.name/?p=199
    yum install $YUM_PACKAGES -y >> $LOG_PATH/install.log 2>&1
    service mysql start >> $LOG_PATH/install.log
fi



###################################################### Install: download
download() {
    printf "    $1... "
    find "/tmp/$1" > /dev/null 2>&1 || wget "$2" -O "/tmp/$1" -q
    echo "complete"
}
# Download install files
echo "[3] Downloading files"
# LuaJIT+CJSON
if [ ! $( which luajit 2> /dev/null ) ]; then
    download "luajit.tar.gz" "http://luajit.org/download/LuaJIT-$LUAJIT_VERSION.tar.gz"
    download "luacjson.tar.gz" "http://www.kyne.com.au/~mark/software/download/lua-cjson-$LUACJSON_VERSION.tar.gz"
fi
# Nginx+DevelKit+Lua
if [ ! $( which nginx 2> /dev/null ) ]; then
    download "nginx.tar.gz" "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"
    download "nginxlua.tar.gz" "https://github.com/chaoslawful/lua-nginx-module/archive/v$NGINXLUA_VERSION.tar.gz"
    download "nginxdevel.tar.gz" "https://github.com/simpl/ngx_devel_kit/archive/v$NGINXDEV_VERSION.tar.gz"
fi
# Node
if [ ! $( which node 2> /dev/null ) ] || [ ! $( which npm 2> /dev/null ) ]; then
    download "node.tar.gz" "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz"
fi

# Untar files
echo "[4] Untarring files"
find /tmp/*.tar.gz 2> /dev/null | xargs -i tar -C /tmp/ -xf {}



###################################################### Install: compile
# Start installing
echo "[5] Compiling & installing"
# LuaJIT+LuaCJSON
if [ ! $( which luajit 2> /dev/null ) ]; then
    printf "    LuaJIT+LuaCJSON... "
    cd /tmp/LuaJIT*
    make >> $LOG_PATH/install.log
    make install PREFIX=$OXYPANEL_PATH >> $LOG_PATH/install.log
    cd /tmp/lua-cjson*
    make -j 2 -w PREFIX=$OXYPANEL_PATH LUA_INCLUDE_DIR=$OXYPANEL_PATH/include/luajit-2.0 >> $LOG_PATH/install.log
    make install PREFIX=$OXYPANEL_PATH >> $LOG_PATH/install.log
    echo "complete"
fi
# Nginx+DevelKit+Lua
if [ ! $( which nginx 2> /dev/null ) ]; then
    printf "    Nginx+DevelKit+Lua... "
    cd /tmp/nginx-*
    export LUAJIT_INC="$OXYPANEL_PATH/include/luajit-2.0"
    export LUAJIT_LIB="$OXYPANEL_PATH/lib"
    ./configure --prefix=$OXYPANEL_PATH --with-http_ssl_module --add-module=../ngx_devel_kit* --add-module=../lua-nginx-module* >> $LOG_PATH/install.log
    make -j 2 -w >> $LOG_PATH/install.log
    make install >> $LOG_PATH/install.log
    echo "complete"
fi
# Node
if [ ! $( which node 2> /dev/null ) ]; then
    printf "    Node... "
    cd /tmp/node-*
    ./configure --prefix=$OXYPANEL_PATH >> $LOG_PATH/install.log
    make -j 2 -w >> $LOG_PATH/install.log 2>&1
    make install >> $LOG_PATH/install.log
    echo "complete"
fi



###################################################### Install: setup
echo "[6] Cloning Oxypanel & Luawa"
mkdir -p "$OXYPANEL_PATH/src"
mkdir -p "$OXYPANEL_PATH/ssh"
mkdir -p "$OXYPANEL_PATH/tmp"
cd $OXYPANEL_PATH/src/
if ! find "$OXYPANEL_PATH/src/.git/index" > /dev/null 2>&1; then
    git clone https://github.com/Oxygem/Oxypanel.git $OXYPANEL_PATH/src >> $LOG_PATH/install.log
    git submodule update --init --recursive >> $LOG_PATH/install.log
fi

echo "[7] Creating SSH key"
find $OXYPANEL_PATH/ssh/oxypanel.key > /dev/null 2>&1 || ssh-keygen -t rsa -N "" -f $OXYPANEL_PATH/ssh/oxypanel.key >> $LOG_PATH/install.log

echo "[8] Building config files"
# Nothing but a bit of inlined python in yo bash
# original plan was to have install.py, but py not guaranteed to be there (Debian)
# but hashing/fiddling with files still a lot easier in python :)
DATA=$( python -c "$( cat <<EOF
import sys
import hashlib
import string
import random
import time

# Read in config
config = open( '{0}/src/scripts/config.example.lua'.format( sys.argv[1] ) ).read()

# Generate two random strings (user secret & node share)
chars = string.ascii_letters + string.digits + '@#$%^*/{}[]'
user_secret = ''.join( random.choice( chars ) for _ in range( 30 ))
node_share = ''.join( random.choice( chars ) for _ in range( 30 ))

# Generate a random sha512 hash for salt
base = ''.join( random.choice( chars ) for _ in range( 30 ))
salt = hashlib.sha512( base ).hexdigest()

# Using default conf settings build a user password (stretching = 1024)
# following matches up with luawa/user.lua's generatePassword function
password_unhashed = 'admin'
password = '{0}{1}'.format( salt, user_secret )
for _ in range( 1024 ):
    password = hashlib.sha512( '{0}{1}'.format( password, password_unhashed ) ).hexdigest()

# Build create user query
mysql_password = ''.join( random.choice( chars ) for _ in range( 30 ))
print 'GRANT ALL ON oxypanel.* TO "oxypanel"@"localhost" IDENTIFIED BY "{0}"'.format( mysql_password )

# Build user insert query
print 'DELETE FROM user WHERE email = "admin@admin.com"; INSERT INTO user ( email, password, salt, \`group\`, name, register_time ) VALUES ( "{0}", "{1}", "{2}", "{3}", "{4}", "{5}" )'.format(
    'admin@admin.com',
    password,
    salt,
    1,
    'change_me',
    int( time.time() )
)

# Prepare config
config = config.replace( 'SSH_KEY_LOCATION', '{0}/ssh/oxypanel.key'.format( sys.argv[1] ))
config = config.replace( 'DATABASE_PASS', mysql_password )
config = config.replace( 'USER_SECRET_KEY', user_secret )
config = config.replace( 'NODE_SHARE_KEY', node_share )

# Echo out config
print config
EOF
)" "$OXYPANEL_PATH" )

# Oxypanel config (uses above)
CONFIG=$( echo "$DATA" | grep -v INSERT | grep -v GRANT )
USER_SQL=$( echo "$DATA" | grep GRANT )
INSERT_SQL=$( echo "$DATA" | grep INSERT )
find $OXYPANEL_PATH/src/config.lua > /dev/null 2>&1 || echo "$CONFIG" > $OXYPANEL_PATH/src/config.lua

# Nginx config
NGINX_CONFIG=$( cat <<EOF
user  daemon;
worker_processes  2;

events {
    worker_connections  1024;
}

http {
    include       mime.types;

    sendfile        on;
    keepalive_timeout  65;

    #resolver
    resolver 8.8.8.8 8.8.4.4;

    #get oxypanel
    include "$OXYPANEL_PATH/src/config.nginx";
}
EOF
)
echo "$NGINX_CONFIG" > "$OXYPANEL_PATH/conf/nginx.conf"


echo "[9] Importing database structure"
echo "CREATE DATABASE IF NOT EXISTS oxypanel" | mysql
echo "$USER_SQL" | mysql oxypanel
mysql oxypanel < $OXYPANEL_PATH/src/scripts/layout.sql
echo "$INSERT_SQL" | mysql oxypanel


echo "[10] Running build script"
cd $OXYPANEL_PATH/src/ && $OXYPANEL_PATH/bin/luajit scripts/build.lua >> $LOG_PATH/install.log


echo "[11] Setting up paths, linking"
touch /root/.profile
echo 'export PATH=$PATH:'"$OXYPANEL_PATH/bin:$OXYPANEL_PATH/sbin" >> /root/.profile
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'"$OXYPANEL_PATH/lib" >> /root/.profile
# Hacky fix for some distros!
mkdir -p /usr/local/lib/lua/5.1/
find /usr/local/lib/lua/5.1/cjson.so > /dev/null 2>&1 || ln -s $OXYPANEL_PATH/lib/lua/5.1/cjson.so /usr/local/lib/lua/5.1/cjson.so


#echo "[12] Starting Oxypanel"
#nginx


# Done!
echo ""
echo "###"
echo "Oxypanel Install Complete"
echo "###"
echo ""
exit 0