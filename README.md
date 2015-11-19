# cloudera-scm
Cloudera SCM Operations

Various gists and scripts related to installing/configuring/operating Cloudera Manager Server and Agent software.



## Contents

### kickstart - Anaconda kickstart files to help automate virtual machine creation

* anaconda-ks-datanode-headless.cfg - Create a smaller virtual machine (storage-wise) suitable for a CDH datanode. ssh access only. No desktop.
* anaconda-ks-scm-server.cfg - Create a 25GB virtual machine suitable to run Cloudera Manager Server software. ssh and desktop enabled.

### scripts - Scripts to install Cloudera Manager software on Cloudera Manager Server or Cloudera Manager Agent

* scripts/install_cdh_recipe.sh - Script to install Cloudera Manager software with Java JDK and MySQL JDBC connector dependencies. Can be used to install Cloudera Manager Server components, Agent components, or both. Defaults to a single-user mode install where all services run as cloudera-scm user.

Run the script as root. Here are some sample variations:

CLOUDERA_AGENT=0 ./install_cdh_recipe.sh    # Install Cloudera Manager Server components. No agent components. Suitable for main Cloudera Manager Server.
CLOUDERA_SERVER=0 ./install_cdh_recipe.sh   # Install agent components. No Server components. Suitable for a CDH datanode.
CM_SERVER_HOSTNAME=myserver TMP_DIR=/opt/download ./install_cdh_recipe.sh    # Install both Server and Agent software. Change name of Cloudera Manager server to myserver (default is scm1). Change download location to /opt/download (default is /tmp/tmpcdh).

See the contents of the script for additional variables that can be overriden.

The install has only been tested on CentOS6 using the single-user mode install.
