#!/bin/bash

CLOUDERA_SERVER=${CLOUDERA_SERVER:-1}   # Cloudra Manager Server: 0=No, 1=Yes
CLOUDERA_AGENT=${CLOUDERA_AGENT:-1}     # Cloudera Agent/Host: 0=No, 1=Yes
SINGLE_USER_MODE=${SINGLE_USER_MODE:-1} # Use common user for Cloudera Agent/Services
                                        #    0=No, 1=Yes
DISABLE_IPTABLES=${DISABLE_IPTABLES:-1} # Disable iptables: 0=No, 1=Yes
DISABLE_SELINUX=${DISABLE_SELINUX:-1}   # Disable selinux: 0=No, 1=Yes

TMP_DIR=/tmp/tmpcdh
PACKAGE_MGR_INSTALL="yum install -y "

# Oracle JDK Download Info
# Credit to https://gist.github.com/P7h/9741922
BASE_URL_8=http://download.oracle.com/otn-pub/java/jdk/8u40-b25/jdk-8u40
## Earlier versions: 
## v8u60 => http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60
## v8u51 => http://download.oracle.com/otn-pub/java/jdk/8u51-b16/jdk-8u51
## v8u45 => http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45
## v8u40 => http://download.oracle.com/otn-pub/java/jdk/8u40-b25/jdk-8u40 # CDH Recommended at this time
## v8u31 => http://download.oracle.com/otn-pub/java/jdk/8u31-b13/jdk-8u31
## v8u25 => http://download.oracle.com/otn-pub/java/jdk/8u25-b17/jdk-8u25
JDK_VERSION=${BASE_URL_8: -8}
JDK_PLATFORM="-linux-x64.tar.gz"
JDK_INSTALL_DIR=/usr/java

CM_SERVER_HOSTNAME=${CM_SERVER_HOSTNAME:-scm1}

# MySQL related variables
MY_CNF_URL="https://s3.amazonaws.com/robhughes/cdh/my.cnf"
TMP_MY_CNF=$TMP_DIR/my.cnf
SYSTEM_MY_CNF=/etc/my.cnf
MYSQL_USER=mysql
MYSQL_ROOT_USER=root
MYSQL_ROOT_PASSWORD="mysqlpassword"
MYSQL_JDBC_CONNECTOR_VERSION=5.1.36
MYSQL_JDBC_CONNECTOR_MD5SUM="9a06f655da5d533a3c1b2565b76306c7"

# Variables used to create various databases
ACTIVITY_MONITOR_DB="${ACTIVITY_MONITOR_DB:-amon}"
ACTIVITY_MONITOR_USER="${ACTIVITY_MONITOR_USER:-amon}"
ACTIVITY_MONITOR_PASS="${ACTIVITY_MONITOR_PASS:-amon_password}"

REPORTS_MANAGER_DB="${REPORTS_MANAGER_DB:-rman}"
REPORTS_MANAGER_USER="${REPORTS_MANAGER_USER:-rman}"
REPORTS_MANAGER_PASS="${REPORTS_MANAGER_PASS:-rman_password}"

HIVE_METASTORE_DB="${HIVE_METASTORE_DB:-metastore}"
HIVE_METASTORE_USER="${HIVE_METASTORE_USER:-hive}"
HIVE_METASTORE_PASS="${HIVE_METASTORE_PASS:-hive_password}"

SENTRY_SERVER_DB="${SENTRY_SERVER_DB:-sentry}"
SENTRY_SERVER_USER="${SENTRY_SERVER_USER:-sentry}"
SENTRY_SERVER_PASS="${SENTRY_SERVER_PASS:-sentry_password}"

NAV_AUDIT_SERVER_DB="${NAV_AUDIT_SERVER_DB:-nav}"
NAV_AUDIT_SERVER_USER="${NAV_AUDIT_SERVER_USER:-nav}"
NAV_AUDIT_SERVER_PASS="${NAV_AUDIT_SERVER_PASS:-nav_password}"

NAV_METADATA_SERVER_DB="${NAV_METADATA_SERVER_DB:-navms}"
NAV_METADATA_SERVER_USER="${NAV_METADATA_SERVER_USER:-navms}"
NAV_METADATA_SERVER_PASS="${NAV_METADATA_SERVER_PASS:-navms_password}"

OOZIE_SERVER_DB="${OOZIE_SERVER_DB:-oozie}"
OOZIE_SERVER_USER="${OOZIE_SERVER_USER:-oozie}"
OOZIE_SERVER_PASS="${OOZIE_SERVER_PASS:-oozie_password}"
#grant all privileges on oozie.* to 'oozie'@'localhost' identified by 'oozie';

# Cloudera Manager Server Database
CM_SERVER_DB="${CM_SERVER_DB:-scm}"
CM_SERVER_USER="${CM_SERVER_USER:-scm}"
CM_SERVER_PASS="${CM_SERVER_PASS:-scm_password}"

# Cloudera Manager variables
CM_VERSION=5.4.7
CM_ROOT=/opt/cloudera-manager
CM_TARBALL_ROOT=/opt/cloudera-manager/cm-$CM_VERSION
CM_TAR_DOWNLOAD_URL=http://archive.cloudera.com/cm5/cm/5/cloudera-manager-el6-cm${CM_VERSION}_x86_64.tar.gz
CM_TAR_DOWNLOAD=$TMP_DIR/cloudera-manager-el6-cm${CM_VERSION}_x86_64.tar.gz
CM_USER=cloudera-scm
CM_SERVER_DATA_DIR=/var
CM_AGENT_VAR_DIR=/var

declare -a CM_DIRS=(/var/log/cloudera-scm-headlamp \
/var/log/cloudera-scm-firehose \
/var/log/cloudera-scm-alertpublisher \
/var/log/cloudera-scm-eventserver \
/var/log/cloudera-scm-server \
/var/log/cloudera-scm-navigator \
/var/lib/cloudera-scm-headlamp \
/var/lib/cloudera-scm-firehose \
/var/lib/cloudera-scm-alertpublisher \
/var/lib/cloudera-scm-eventserver \
/var/lib/cloudera-scm-navigator \
/var/lib/cloudera-scm-server \
/opt/cloudera \
/var/lib/oozie \
/var/lib/cloudera-host-monitor \
/var/lib/cloudera-service-monitor \
/opt/cm \    # Top-level dir for services that need a data dir
)

declare -a CM_AGENT_DIRS=(/var/log/cloudera-scm-agent \
/var/log/cloudera-scm-navigator \
/var/log/zookeeper \
/var/log/hadoop-hdfs \
/var/log/hadoop-httpfs \
/var/log/sqoop2 \
/var/log/solr \
/var/log/hadoop-yarn \
/var/log/hadoop-mapreduce \
/var/log/hive \
/var/log/oozie \
/var/log/hue \
/var/log/hcatalog \
/var/lib/cloudera-scm-agent \
/opt/cloudera \
/opt/cloudera/parcels \
/opt/cloudera/parcels-cache \
/var/lib/oozie \
/var/lib/hue \
/var/lib/cloudera-host-monitor \
/var/lib/cloudera-service-monitor \
/var/lib/cloudera-scm-navigator \
/var/lib/zookeeper \
/var/lib/zookeeper/version-2 \
/var/lib/hadoop-hdfs \
/var/lib/hadoop-httpfs \
/var/lib/sqoop2 \
/var/lib/solr \
/var/lib/hadoop-yarn \
/var/run/hdfs-sockets \
/var/run/hdfs-sockets/dn \
/var/run/hadoop-httpfs \
/opt/cm \    # Top-level dir for services that need a data dir
/etc/hadoop \
/etc/hive \
)

PARCEL_REPO_DIR=/opt/cloudera/parcel-repo
PARCEL_DIR=/opt/cloudera/parcels

EXTJS_URL= http://archive.cloudera.com/gplextras/misc/ext-2.2.zip

# Tune kernel parameters
# vm.swapiness setting
VM_SWAPPINESS_VALUE=10

# /sys/kernel/mm/redhat_transparent_hugepage/defrag
HUGEPAGE_VALUE=never

function abort 
{
   echo "$1"
   exit 1
}

function log_msg
{
   echo "$1"
}

# Credit to https://gist.github.com/Mins/4602864
function mysql_secure_install
{
local MYSQL_PASSWORD=

$PACKAGE_MGR_INSTALL expect > /dev/null 2>&1

if [ "$?" -ne 0 ]; then
   abort "error: failed to install expect package. Exiting..."
fi

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn /usr/bin/mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MYSQL_PASSWORD\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"
}

if [ $(id -u) -ne 0 ]; then
   abort "error: this script must be run by root user. Exiting..."
fi

umask 0022

WGET=$(which wget)
SHA1SUM=$(which sha1sum)

if [ -z "$WGET" ]; then
   abort "error: no wget available. exiting..."
fi

if [ ! -e "$TMP_DIR" ]; then
   mkdir -p $TMP_DIR
fi

log_msg "info: installed  Cloudera Manager dependencies..."
$PACKAGE_MGR_INSTALL  chkconfig python bind-utils psmisc libxslt zlib sqlite cyrus-sasl-plain cyrus-sasl-gssapi fuse portmap fuse-libs redhat-lsb > /dev/null 2>&1

if [ ! -e "$TMP_DIR/$JDK_VERSION$JDK_PLATFORM" ]; then
   log_msg "info: downloading Oracle JDK $JDK_VERSION$JDK_PLATFORM to $TMP_DIR..."
   $WGET --quiet -c -O "$TMP_DIR/$JDK_VERSION$JDK_PLATFORM" --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "${BASE_URL_8}${JDK_PLATFORM}"
fi
if [ ! -e "$TMP_DIR/$JDK_VERSION$JDK_PLATFORM" ]; then
   abort "error: failed to download Oracle JDK. Exiting..."
fi

log_msg "info: found Oracle JDK download."

if [ ! -e "$JDK_INSTALL_DIR" ]; then
   mkdir -p "$JDK_INSTALL_DIR"
   chmod 755 "$JDK_INSTALL_DIR"
fi

JDK_TOP_DIR=$(tar -tzf "$TMP_DIR/$JDK_VERSION$JDK_PLATFORM" | head -1 | sed -e "s|/||")
if [ ! -d "$JDK_INSTALL_DIR/$JDK_TOP_DIR" ]; then
   log_msg "info: installing jdk $JDK_TOP_DIR..."
   tar xzf "$TMP_DIR/$JDK_VERSION$JDK_PLATFORM" -C "$JDK_INSTALL_DIR"
fi

if [ ! -d "$JDK_INSTALL_DIR/$JDK_TOP_DIR" ]; then
   abort "error: jdk not installed in $JDK_INSTALL_DIR/$JDK_TOP_DIR. Exiting..."
fi

log_msg "info: jdk installed in $JDK_INSTALL_DIR/$JDK_TOP_DIR."


if [ "$CLOUDERA_SERVER" -eq 1 ]; then

if [ ! -e "$TMP_MY_CNF" ]; then
   log_msg "info: downloading my.cnf from $MY_CNF_URL"
   $WGET $MY_CNF_URL -O $TMP_MY_CNF
   if [ "$?" -ne 0 ] || [ ! -e "$TMP_MY_CNF" ]; then
      abort "error: failed to download my.cnf. exiting...."
   fi
fi

yum list installed mysql-server > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
   log_msg "info: installing mysql-server..."
   yum install -y mysql-server
   if [ "$?" -ne 0 ]; then
      abort "error: failed to install mysql-server"
   fi
fi
   
yum list installed mysql-server > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
   abort "error: mysql-server not installed"
else
   log_msg "info: mysql-server installed."
fi

MYSQL_USER_GROUP=$(groups mysql | awk '{ print $3 }')
if [ -z "$MYSQL_USER_GROUP" ]; then
   abort "error: could not determine group for mysql user '$MYSQL_USER'. Exiting..."
fi

MY_CNF_CHANGED=0
if [ -n "$SHA1SUM" ]; then
   if [ "$($SHA1SUM $TMP_MY_CNF | awk '{ print $1 }')" != "$($SHA1SUM $SYSTEM_MY_CNF | awk '{ print $1 }')" ]; then
     log_msg "info: installing $TMP_MY_CNF to ${SYSTEM_MY_CNF}..."
     /bin/cp -fp $SYSTEM_MY_CNF "${SYSTEM_MY_CNF}.$(date '+%s')"
     /bin/cp -f $TMP_MY_CNF $SYSTEM_MY_CNF
     if [ "$?" -ne 0 ]; then
        abort "error: non-zero return status installing custom my.cnf. Exiting..."
     fi

     MY_CNF_CHANGED=1
  fi
else
     /bin/cp -fp $SYSTEM_MY_CNF "${SYSTEM_MY_CNF}.$(date \"+%s\")"
     /bin/cp -f $TMP_MY_CNF $SYSTEM_MY_CNF
     if [ "$?" -ne 0 ]; then
        abort "error: non-zero return status installing custom my.cnf. Exiting..."
     fi
     MY_CNF_CHANGED=1
fi

chown $MYSQL_USER:$MYSQL_USER_GROUP $SYSTEM_MY_CNF

MYSQL_BIN_LOG=$(grep "^log_bin" $TMP_MY_CNF  | awk -F= '{ print $2 }')
if [ -z "$MYSQL_BIN_LOG" ]; then
   abort "error: could not determine mysql binary log location. Exiting..."
fi

if [ ! -e "$MYSQL_BIN_LOG" ]; then
   log_msg "info: creating $MYSQL_BIN_LOG directory..."
   mkdir -p $MYSQL_BIN_LOG
fi

chown $MYSQL_USER:$MYSQL_USER_GROUP $MYSQL_BIN_LOG

if [ "$MY_CNF_CHANGED" -eq "1" ]; then
   log_msg "info: restarting mysqld..."
   service mysqld stop
   service mysqld start
fi

/sbin/chkconfig mysqld on
#/sbin/chkconfig --list mysqld

if [ ! -e "$TMP_DIR/.step_secure_mysql" ]; then

   log_msg "info: securing mysql..."
   mysql_secure_install
 
   /usr/bin/mysqladmin -u root password "$MYSQL_ROOT_PASSWORD" 
   /usr/bin/mysqladmin -u root -h $(hostname -s) password "$MYSQL_ROOT_PASSWORD" 
   touch "$TMP_DIR/.step_secure_mysql"
fi

log_msg "info: MySQL installation has been secured"

#Installing the MySQL JDBC Driver
#Install the JDBC driver on the Cloudera Manager Server host, as well as hosts to which you assign the Activity Monitor, Reports Manager, Hive Metastore Server, Sentry Server, Cloudera Navigator Audit Server, and Cloudera Navigator Metadata Server roles.
#  Note: If you already have the JDBC driver installed on the hosts that need it, you can skip this section. However, MySQL 5.6 requires a driver version 5.1.26 or higher.
#Cloudera recommends that you assign all roles that require databases on the same host and install the driver on that host. Locating all such roles on the same host is recommended but not required. If you install a role, such as Activity Monitor, on one host and other roles on a separate host, you would install the JDBC driver on each host running roles that access the database. 

fi # if [ "$CLOUDERA_SERVER" -eq 1 ]; then

if [ ! -e "$TMP_DIR/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}.tar.gz" ]; then
   log_msg "info: Downloading MySQL JDBC Connector..."
   $WGET --quiet http://downloads.mysql.com/archives/get/file/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}.tar.gz -O $TMP_DIR/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}.tar.gz
fi

if [ ! -e "$TMP_DIR/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}.tar.gz" ]; then
   abort "error: failed to download MySQL JDBC connector. Exiting..."
fi

if [ -n "$MYSQL_JDBC_CONNECTOR_MD5SUM" ]; then
   if [ "$MYSQL_JDBC_CONNECTOR_MD5SUM" != "$(md5sum $TMP_DIR/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}.tar.gz | awk '{ print $1 }')" ]; then
   abort "error: invalid md5sum for $TMP_DIR/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}.tar.gz. Exiting..."
   fi
fi

log_msg "info: Found MySQL JDBC Connector archive file."

if [ ! -e /usr/share/java/mysql-connector-java.jar ]; then
   log_msg "info: installing MySQL JDBC Connector..."
   mkdir -p /usr/share/java
   chmod 755 /usr/share/java
   pushd $TMP_DIR
   tar xzf mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}.tar.gz
   cp mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}-bin.jar /usr/share/java/mysql-connector-java.jar
   chmod 644 /usr/share/java/mysql-connector-java.jar
   popd
fi

if [ ! -e /usr/share/java/mysql-connector-java.jar ]; then
   abort "error: failed to install MySQL JDBC connector. Exiting..."
else
   log_msg "info: successfully installed MySQL JDBC Connector."
fi

if [ "$CLOUDERA_SERVER" -eq 1 ]; then

ERROR_OCCURRED=0
if [ ! -e "$TMP_DIR/.step_create_databases" ]; then
   log_msg "info: creating activity monitor database..."
   mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "create database $ACTIVITY_MONITOR_DB DEFAULT CHARACTER SET utf8; GRANT ALL ON $ACTIVITY_MONITOR_DB.* TO '$ACTIVITY_MONITOR_USER'@'%' IDENTIFIED BY '$ACTIVITY_MONITOR_PASS'"

   if [ "$?" -ne "0" ]; then
      log_msg "error: non-zero return status when creating database."
      ERROR_OCCURRED=1
   fi

   log_msg "info: creating reports manager database..."
   mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "create database $REPORTS_MANAGER_DB DEFAULT CHARACTER SET utf8; GRANT ALL ON $REPORTS_MANAGER_DB.* TO '$REPORTS_MANAGER_USER'@'%' IDENTIFIED BY '$REPORTS_MANAGER_PASS'"

   if [ "$?" -ne "0" ]; then
      log_msg "error: non-zero return status when creating database."
      ERROR_OCCURRED=1
   fi

   log_msg "info: creating hive metastore database..."
   mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "create database $HIVE_METASTORE_DB DEFAULT CHARACTER SET utf8; GRANT ALL ON $HIVE_METASTORE_DB.* TO '$HIVE_METASTORE_USER'@'%' IDENTIFIED BY '$HIVE_METASTORE_PASS'" 

   if [ "$?" -ne "0" ]; then
      log_msg "error: non-zero return status when creating database."
      ERROR_OCCURRED=1
   fi

   log_msg "info: creating sentry server database..."
   mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "create database $SENTRY_SERVER_DB DEFAULT CHARACTER SET utf8; GRANT ALL ON $SENTRY_SERVER_DB.* TO '$SENTRY_SERVER_USER'@'%' IDENTIFIED BY '$SENTRY_SERVER_PASS'"

   if [ "$?" -ne "0" ]; then
      log_msg "error: non-zero return status when creating database."
      ERROR_OCCURRED=1
   fi

   log_msg "info: creating cloudera navigator audit server database..."
   mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "create database $NAV_AUDIT_SERVER_DB DEFAULT CHARACTER SET utf8; GRANT ALL ON $NAV_AUDIT_SERVER_DB.* TO '$NAV_AUDIT_SERVER_USER'@'%' IDENTIFIED BY '$NAV_AUDIT_SERVER_PASS'"

   if [ "$?" -ne "0" ]; then
      log_msg "error: non-zero return status when creating database."
      ERROR_OCCURRED=1
   fi

   log_msg "info: creating cloudera navigator metadata server database..."
   mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "create database $NAV_METADATA_SERVER_DB DEFAULT CHARACTER SET utf8; GRANT ALL ON $NAV_METADATA_SERVER_DB.* TO '$NAV_METADATA_SERVER_USER'@'%' IDENTIFIED BY '$NAV_METADATA_SERVER_PASS'" 
   if [ "$?" -ne "0" ]; then
      log_msg "error: non-zero return status when creating database."
      ERROR_OCCURRED=1
   fi

   log_msg "info: creating oozie server database..."
   mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "create database $OOZIE_SERVER_DB; GRANT ALL PRIVILEGES ON $OOZIE_SERVER_DB.* TO '$OOZIE_SERVER_USER'@'%' IDENTIFIED BY '$OOZIE_SERVER_PASS'" 
   if [ "$?" -ne 0 ]; then
      log_msg "error: non-zero return status when creating database."
      ERROR_OCCURRED=1
   fi
   
   if [ "$ERROR_OCCURRED" -eq 0 ]; then
      log_msg "info: databases created."
      touch "$TMP_DIR/.step_create_databases"
   fi
else
   log_msg "info: databases already created."
fi

fi # if [ "$CLOUDERA_SERVER" -eq 1 ]; then

# Install Cloudera Manager
mkdir -p "$CM_ROOT"

if [ -e "$CM_ROOT" ]; then
   log_msg "info: Cloudera Manager root dir $CM_ROOT exists."
else
   aboart "error: failed to create Cloudera Manager root dir $CM_ROOT exists. Exiting."
fi

log_msg "info: checking Cloudera Manager install..."
if [ ! -e "$CM_TAR_DOWNLOAD" ]; then
   log_msg "info: downloading Cloudera Manager $CM_VERSION..."
   $WGET --quiet "$CM_TAR_DOWNLOAD_URL" -O "$CM_TAR_DOWNLOAD"
   if [ "$?" -ne 0 ]; then
      abort "error: failed to download Cloudera Manager tar file. Exiting."
   fi
fi

log_msg "info: Cloudera Manager tar file exists."

if [ ! -e "$CM_TARBALL_ROOT" ]; then
   log_msg "info: extracting Cloudera Manager tarball to Cloudera Manager root dir $CM_ROOT..."
   tar xzf "$CM_TAR_DOWNLOAD" -C "$CM_ROOT"
fi

log_msg "info: Cloudera Manager installed to $CM_TARBALL_ROOT."

CM_MAJOR_VERSION=$(echo "$CM_VERSION" | awk -F. '{ print $1 }')
if [ -z "$CM_MAJOR_VERSION" ]; then
   abort "error: could not determine Cloudera Manager major version. Exiting..."
fi

if [ ! -e "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0" ]; then
   ln -s "$CM_TARBALL_ROOT" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"
fi

log_msg "info: Ensuring JAVA_HOME set to $JDK_INSTALL_DIR/$JDK_TOP_DIR in $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default/cloudera-scm-server..."
grep "^export JAVA_HOME=" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-server > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
   echo "export JAVA_HOME=$JDK_INSTALL_DIR/$JDK_TOP_DIR" >> "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-server
fi

grep "$CM_USER" /etc/passwd
if [ "$?" -ne 0 ]; then
   log_msg "info: Creating Cloudera Manager user $CM_USER..."
   useradd --system --home="/opt/cloudera-manager/cm-${CM_MAJOR_VERSION}.0/run/cloudera-scm-server" --no-create-home --shell=/bin/false --comment "Cloudera SCM User" "$CM_USER" > /dev/null 2>&1
   if [ "$?" -ne 0 ]; then
      abort "error: failed to create Cloudera Manager user $CM_USER. Exiting..."
   fi
   grep "$CM_USER" /etc/passwd > /dev/null 2>&1
   if [ "$?" -ne 0 ]; then
      abort "error: failed to create Cloudera Manager user $CM_USER. Exiting..."
   fi
fi

log_msg "info: Cloudera Manager user $CM_USER exists."

mkdir -p "$CM_SERVER_DATA_DIR"
if [ ! -d "$CM_SERVER_DATA_DIR" ]; then
   abort "error: failed to create Cloudera Manager Server data dir $CM_SERVER_DATA_DIR. Exiting..."
fi

log_msg "info: Ensuring CMF_VAR points to $CM_SERVER_DATA_DIR in $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default/cloudera-scm-server..."
sed -i -e "s|^export CMF_VAR=.*$|export CMF_VAR=$CM_SERVER_DATA_DIR|" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-server

log_msg "info: Clouder Manager Server data dir $CM_SERVER_DATA_DIR exists."

#Configure Cloudera Manager Agents

#On every Cloudera Manager Agent host, configure the Cloudera Manager Agent to point to the Cloudera Manager Server by setting the following properties in the tarball_root/etc/cloudera-scm-agent/config.ini configuration file:
#    Property 	Description
#    server_host 	Name of the host where Cloudera Manager Server is running.
#    server_port 	Port on the host where Cloudera Manager Server is running.
#    By default, a tarball installation has a var subdirectory where state is stored. In a non-tarball installation, state is stored in /var. Cloudera recommends that you reconfigure the tarball installation to use an external directory as the /var equivalent (/var or any other directory outside the tarball) so that when you upgrade Cloudera Manager, the new tarball installation can access this state. Configure the installation to use an external directory for storing state by editing tarball_root/etc/default/cloudera-scm-agent and setting the CMF_VAR variable to the location of the /var equivalent. If you do not reuse the state directory between different tarball installations, duplicate Cloudera Manager Agent entries can occur in the Cloudera Manager database.

if [ "$CLOUDERA_AGENT" -eq 1 ]; then
   log_msg "info: Ensuring Cloudera Agent var dir $CM_AGENT_VAR_DIR exists..."
   mkdir -p "$CM_AGENT_VAR_DIR"

   log_msg "info: Ensuring CMF_VAR points to $CM_AGENT_VAR_DIR in $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default/cloudera-scm-agent..."
   sed -i -e "s|^export CMF_VAR=.*$|export CMF_VAR=$CM_AGENT_VAR_DIR|" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-agent

   if [ "$SINGLE_USER_MODE" -eq 1 ]; then
      log_msg "info: configuring Cloudera Agent server for Single User Mode..."

      log_msg "info: Ensuring USER set to $CM_USER in $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default/cloudera-scm-agent..."
      grep "^export USER=" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-agent > /dev/null 2>&1
      if [ "$?" -ne 0 ]; then
         echo "export USER=$CM_USER" >> "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-agent
      fi
      log_msg "info: checking sudoers rules..."
      grep "^Defaults[ ]\+secure_path = .*" /etc/sudoers > /dev/null 2>&1
      if [ "$?" -ne 0 ]; then
         log_msg "info: adding secure_patch setting to /etc/sudoers..."
         echo "Defaults[ ]\+secure_path = /sbin:/bin:/usr/sbin:/usr/bin" >> /etc/sudoers
      fi
      grep "^Defaults[ ]\+secure_path = /sbin:/bin:/usr/sbin:/usr/bin" /etc/sudoers > /dev/null 2>&1
      if [ "$?" -ne 0 ]; then
         log_msg "info: secure_patch setting in /etc/sudoers..."
         sed -i -e "s|^\(Defaults[ ]\+secure_path = \).*|\1/sbin:/bin:/usr/sbin:/usr/bin|" /etc/sudoers
      fi

      SUDOER_RULE="Defaults:$CM_USER !requiretty"
      grep "^$SUDOER_RULE" /etc/sudoers > /dev/null 2>&1
      if [ "$?" -ne 0 ]; then
         log_msg "info: adding 'Defaults:$CM_USER !requiretty' rule to /etc/suoders"
         echo "$SUDOER_RULE" >> /etc/sudoers
      fi

      SUDOER_RULE="%$CM_USER ALL=(ALL) NOPASSWD: ALL"
      grep "^$SUDOER_RULE" /etc/sudoers.d/* > /dev/null 2>&1
      if [ "$?" -ne 0 ]; then
         log_msg "info: Adding passwordless sudo rule in /etc/sudoers.d/cloudera_single_user_mode for $CM_USER user..."
         echo "$SUDOER_RULE" >> /etc/sudoers.d/cloudera_single_user_mode
      fi

      if [ ! -e "/etc/security/limits.d/${CM_USER}.conf" ]; then
         log_msg "info: creating per user limits for user $CM_USER in /etc/security/limits.d/${CM_USER}.conf..."
         cat > /etc/security/limits.d/${CM_USER}.conf << EOF
$CM_USER soft nofile 32768
$CM_USER soft nproc 65536
$CM_USER hard nofile 1048576
$CM_USER hard nproc unlimited
$CM_USER hard memlock unlimited
$CM_USER soft memlock unlimited
EOF
   fi

   if [ -e /etc/pam.d/su ]; then
      grep "^session required pam_limits.so" /etc/pam.d/su > /dev/null 2>&1
      if [ "$?" -ne 0 ]; then
         log_msg "info: enabling per user su limits in /etc/pam.d/su..."
         echo "session required pam_limits.so" >> /etc/pam.d/su
      fi
   else
      log_msg "warn: could not enable per user su limits. /etc/pam.d/su does not exist."
   fi
   
   fi # if [ "$SINGLE_USER_MODE" -eq 1 ]; then
   log_msg "info: Ensuring JAVA_HOME set to $JDK_INSTALL_DIR/$JDK_TOP_DIR in $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default/cloudera-scm-agent..."
   grep "^export JAVA_HOME=" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-agent > /dev/null 2>&1
   if [ "$?" -ne 0 ]; then
      echo "export JAVA_HOME=$JDK_INSTALL_DIR/$JDK_TOP_DIR" >> "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-agent
   fi

   log_msg "info: Ensuring server_host property in $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/cloudera-scm-agent/config.ini points to $CM_SERVER_HOSTNAME..."
   sed -i -e "s/^server_host=.*$/server_host=$CM_SERVER_HOSTNAME/" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/cloudera-scm-agent/config.ini


for dir in "${CM_AGENT_DIRS[@]}"; do
   log_msg "info: Ensuring Cloudera Manager Agent dir $dir exists..."
   mkdir -p "$dir"
   chown -R "$CM_USER":"$CM_USER" "$dir" 
done

if [ ! -e /var/lib/oozie/mysql-connector-java.jar ]; then
   log_msg "info: installing MySQL JDBC Connector to /var/lib/oozie..."
   pushd /var/lib/oozie
   cp $TMP_DIR/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_JDBC_CONNECTOR_VERSION}-bin.jar /var/lib/oozie/mysql-connector-java.jar
   chmod 644 /var/lib/oozie/mysql-connector-java.jar
   chown $CM_USER:$CM_USER /var/lib/oozie/mysql-connector-java.jar
   log_msg "info: installing ExtJS for Oozie..."
   wget EXTJS_URL
   if [ "$?" -eq 0 ]; then
      $JDK_INSTALL_DIR/$JDK_TOP_DIR/bin/jar xvf ext-*.zip 
      chown -R $CM_USER:$CM_USER ext*
   else
      log_msg "warn: Error downloading ExtJS for Ooozie. Th Oozie Web Console will not work until ExtJS is installed"
   fi 
   popd
fi
fi # if [ "$CLOUDERA_AGENT" -eq 1 ]; then

for dir in "${CM_DIRS[@]}"; do
   log_msg "info: Ensuring Cloudera Manager Server dir $dir exists..."
   mkdir -p "$dir"
   chown -R "$CM_USER":"$CM_USER" "$dir" 
done

if [ "$CLOUDERA_SERVER" -eq 1 ]; then

log_msg "info: checking to see if Cloudera Manager Server database exists..."
#grep "^com.cloudera.cmf.db.type" /opt/cloudera-manager/cm-5.0/etc/cloudera-scm-server/db.properties > /dev/null 2>&1
mysql -uroot -pmysqlpassword -e "show databases" | grep "^${CM_SERVER_DB}$" > /dev/null
if [ "$?" -ne 0 ]; then
   log_msg "info: creating Cloudera Manager Server database..."
   "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/share/cmf/schema/scm_prepare_database.sh mysql --config-path="$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/cloudera-scm-server -uroot -p"$MYSQL_ROOT_PASSWORD" "$CM_SERVER_DB" "$CM_SERVER_USER" "$CM_SERVER_PASS" 
fi

mysql -uroot -pmysqlpassword -e "show databases" | grep "^${CM_SERVER_DB}$" > /dev/null
if [ "$?" -eq 0 ]; then
   log_msg "info: Cloudera Manager Server database exists."
else
   abort "error: failed to create Cloudera Manager Server database. Exiting..."
fi

fi # if [ "$CLOUDERA_SERVER" -eq 1 ]; then

log_msg "info: checking if parcel directories exist..."

if [ "$CLOUDERA_SERVER" -eq 1 ]; then
   mkdir -p "$PARCEL_REPO_DIR"
   chown -R $CM_USER:$CM_USER "$PARCEL_REPO_DIR"
fi


if [ "$CLOUDERA_AGENT" -eq 1 ]; then
   mkdir -p "$PARCEL_DIR"
   chown -R $CM_USER:$CM_USER "$PARCEL_DIR"
fi

# Create service init files for Cloudera Manager Server
if [ "$CLOUDERA_SERVER" -eq 1 ]; then
   grep "^export CMF_SUDO_CMD=" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default/cloudera-scm-server" > /dev/null 2>&1
   if [ "$?" -eq 0 ]; then
     sed -i -e '/export CMF_SUDO_CMD/s/^/#/' "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-server 
   fi

   grep "^USER=" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server" > /dev/null 2>&1
   if [ "$?" -eq 0 ]; then
      sed -i -e "s/USER=.*/USER=$CM_USER/" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server"
   else
      abort "error: $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server does not contain USER= line as expected."
   fi
   grep "^GROUP=" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server" > /dev/null 2>&1
   if [ "$?" -eq 0 ]; then
      sed -i -e "s/GROUP=.*/GROUP=$CM_USER/" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server"
   else
      abort "error: $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server does not contain GROUP= line as expected."
   fi

   sed -i -e "s|CMF_DEFAULTS=\${CMF_DEFAULTS:-/etc/default}|CMF_DEFAULTS=\${CMF_DEFAULTS:-$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default}|" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server"

   if [ ! -e /etc/init.d/cloudera-scm-server ] || [ "$($SHA1SUM /etc/init.d/cloudera-scm-server | awk '{ print $1 }')" != "$($SHA1SUM $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server  | awk '{ print $1 }')" ]; then
      log_msg "info: installing Cloudera Manager Server service init file to $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server..."
      cp "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-server" /etc/init.d
   fi

   if [ ! -e /etc/init.d/cloudera-scm-server ]; then
      abort "error: failed to install Cloudera Manager Server service init file to /etc/init.d/cloudera-scm-server. Exiting..."
   fi
   chkconfig cloudera-scm-server on > /dev/null

   log_msg "info: Cloudera Manager Server service init file installed."
   log_msg "info: Start Cloudera Manager Server via 'sudo service cloudera-scm-server start'"
fi # if [ "$CLOUDERA_SERVER" -eq 1 ]; then

# Create service init files for Cloudera Manager Agent 
if [ "$CLOUDERA_AGENT" -eq 1 ]; then
   grep "^export CMF_SUDO_CMD=" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default/cloudera-scm-agent" > /dev/null 2>&1
   if [ "$?" -eq 0 ]; then
     sed -i -e '/export CMF_SUDO_CMD/s/^/#/' "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0"/etc/default/cloudera-scm-agent
   fi

   sed -i -e "s|CMF_DEFAULTS=\${CMF_DEFAULTS:-/etc/default}|CMF_DEFAULTS=\${CMF_DEFAULTS:-$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/default}|" "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-agent"

   if [ ! -e /etc/init.d/cloudera-scm-agent ] || [ "$($SHA1SUM /etc/init.d/cloudera-scm-agent | awk '{ print $1 }')" != "$($SHA1SUM $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-agent  | awk '{ print $1 }')" ]; then
      log_msg "info: installing Cloudera Manager Agent service init file to $CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-agent..."
      cp "$CM_ROOT/cm-${CM_MAJOR_VERSION}.0/etc/init.d/cloudera-scm-agent" /etc/init.d
   fi

   if [ ! -e /etc/init.d/cloudera-scm-agent ]; then
      abort "error: failed to install Cloudera Manager Agent service init file to /etc/init.d/cloudera-scm-agent. Exiting..."
   fi
   chkconfig cloudera-scm-agent on > /dev/null

   log_msg "info: Cloudera Manager Agent service init file installed."
   log_msg "info: Start Cloudera Manager agent via 'sudo service cloudera-scm-agent start'"
fi # if [ "$CLOUDERA_AGENT" -eq 1 ]; then


# Add iptables firewall rules for Cloudera Manager Server  
IPTABLES=$(which iptables)
if [ "$CLOUDERA_SERVER" -eq 1 ] && [ -n "$IPTABLES" ]; then
   grep "dport 7180" /etc/sysconfig/iptables > /dev/null 2>&1
   if [ "$?" -ne 0 ]; then
      log_msg "info: updating firewall rules for Cloudera Manager Server..."
      sed -i '/dport 22 -j ACCEPT/a\
-A INPUT -p tcp -m tcp --dport 7180 -j ACCEPT \
-A INPUT -p tcp -m tcp --dport 7182 -j ACCEPT \
-A INPUT -p tcp -m tcp --dport 7183 -j ACCEPT' /etc/sysconfig/iptables
      service iptables restart
   fi
fi # if [ "$CLOUDERA_SERVER" -eq 1 ] && [ -n "$IPTABLES" ]; then

if [ "$CLOUDERA_AGENT" -eq 1 ] && [ -n "$IPTABLES" ]; then
   grep "dport 8020" /etc/sysconfig/iptables > /dev/null 2>&1
   if [ "$?" -ne 0 ]; then
      log_msg "info: updating firewall rules for Cloudera Manager Agent..."
      sed -i '/dport 22 -j ACCEPT/a\
-A INPUT -p tcp -m tcp --dport 8020 -j ACCEPT \
-A INPUT -p tcp -m tcp --dport 9000 -j ACCEPT \
-A INPUT -p tcp -m tcp --dport 50010 -j ACCEPT' /etc/sysconfig/iptables
      service iptables restart
   fi
fi # if [ "$CLOUDERA_AGENT" -eq 1 ] && [ -n "$IPTABLES" ]; then

# Tune kernel parameters to Cloudera recommended settings
log_msg "info: checking system/kernel settings..."
VM_SWAPPINESS_CURRENT=$(sysctl -n vm.swappiness)
if [ "$VM_SWAPPINESS_CURRENT" != "$VM_SWAPPINESS_VALUE" ]; then
   log_msg "info: setting vm.swappiness value to $VM_SWAPPINESS_VALUE..."
   sysctl -w vm.swappiness=$VM_SWAPPINESS_VALUE
fi
grep vm.swappiness /etc/sysctl.conf > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
   echo "vm.swappiness = $VM_SWAPPINESS_VALUE" >> /etc/sysctl.conf
fi

# Make the vm.swappiness setting persist across reboots
sed -i -e "s/^vm.swappiness = .*$/vm.swappiness = $VM_SWAPPINESS_VALUE/" /etc/sysctl.conf

cat /sys/kernel/mm/redhat_transparent_hugepage/defrag | grep "\[${HUGEPAGE_VALUE}\]"
if [ "$?" -ne 0 ]; then
   log_msg "info: setting /sys/kernel/mm/redhat_transparent_hugepage/defrag to $HUGEPAGE_VALUE..."
   echo "$HUGEPAGE_VALUE" >  /sys/kernel/mm/redhat_transparent_hugepage/defrag
fi

# Make the hugepage setting persist across reboots
if [ -e "/etc/rc.local" ]; then
   grep "/sys/kernel/mm/redhat_transparent_hugepage/defrag" /etc/rc.local > /dev/null 2>&1
   if [ "$?" -ne 0 ]; then
      echo "echo $HUGEPAGE_VALUE > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >> /etc/rc.local
   fi
else
   log_msg "warn: This server does not use an /etc/rc.local init script. You will need to manually set the '/sys/kernel/mm/redhat_transparent_hugepage/defrag' parameter to 'never' on this server."
fi


if [ -n "$IPTABLES" ]; then
   if [ "$DISABLE_IPTABLES" -eq 1 ]; then
      chkconfig iptables off
      service iptables stop
      log_msg "info: Reminder: iptables is disabled."
   else
      chkconfig iptables on
      service iptables start
      log_msg "info: iptables is enabled."
   fi
else
   log_msg "warn: No iptables on this host. You may need to manually configure the firewall for this server."
fi
if [ "$DISABLE_SELINUX" -eq 1 ]; then
   sed -i -e "s/^SELINUX=.*/SELINUX=permissive/" /etc/selinux/config
   log_msg "info: Reminder: SELinux is disabled."
else
   sed -i -e "s/^SELINUX=.*/SELINUX=enforcing/" /etc/selinux/config
   log_msg "info: SELinux is enabled."
fi
log_msg "info: Add hosts to /etc/hosts"
if [ "$SINGLE_USER_MODE" -eq 1 ]; then
   log_msg "info: Remember to enable single user mode in Cloudera Manager."
   log_msg "      Go to Administration > Settings > Advanced."
   log_msg "      Check the Single User Mode checkbox. Then save changes"
   log_msg ""
   log_msg "      Check configuration settings for HDFS data dir."
fi # if [ "$SINGLE_USER_MODE" -eq 1 ]; then
log_msg "info: Remember to start cloudera manager server and agent services"
log_msg ""
log_msg "info: Remember to create /user/hue directory in HDFS after deploying CDH to cluster to workaround the hive service failed test 'The Hive Metastore canary failed to create the hue hdfs home directory'. e.g."
log_msg "      sudo -u cloudera-scm hadoop fs -mkdir /user/hue"
log_msg "      sudo -u cloudera-scm hadoop fs -chmod 1777 /user/hue"

