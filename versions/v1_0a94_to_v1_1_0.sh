#!/bin/bash

#
# This version upgrade script is a shell that explains how an upgrade script should be
# developed. It also includes a list of steps to perform depending on the kind of upgrade
# necessary for a specific upgrade of a version A to a version B.
#
# NOTE: this first upgrade script is just in that package for demonstration purposes only
#       the first structWSF version that can be upgraded is 1.0a92
#

STRUCTWSFVERSION="1.1.0"
STRUCTWSFPREVIOUSVERSION="1.0a94"

STRUCTWSFFOLDER=$1

STRUCTWSFDOWNLOADURL="https://github.com/downloads/structureddynamics/structWSF-Open-Semantic-Framework/structWSF-v$STRUCTWSFVERSION.zip"

# From: http://tldp.org/LDP/abs/html/colorizing.html
# Colorizing the installation process.

black='\E[1;30;40m'
red='\E[1;31;40m'
green='\E[1;32;40m'
yellow='\E[1;33;40m'
blue='\E[1;34;40m'
magenta='\E[1;35;40m'
cyan='\E[1;36;40m'
white='\E[1;37;40m'

cecho ()                     # Color-echo.
                             # Argument $1 = message
                             # Argument $2 = color
{
  local default_msg="No message passed."
                             # Doesn't really need to be a local variable.

  message=${1:-$default_msg}   # Defaults to default message.
  color=${2:-$white}           # Defaults to white, if not specified.

  echo -e "$color"
  echo -e "$message"
  
  tput sgr0                     # Reset to normal.

  return
}

cecho "\n\nBackuping the current version's files...\n"

DATA_INI=$( sed -rn '\|data_ini| s|.*public.*static.*=.*"(.+)".*|\1|p' ${STRUCTWSFFOLDER}/framework/WebService.php )
NETWORK_INI=$( sed -rn '\|network_ini| s|.*public.*static.*=.*"(.+)".*|\1|p' ${STRUCTWSFFOLDER}/framework/WebService.php )

sudo cp -af $STRUCTWSFFOLDER"/" "/tmp/structWSF-backup-"$STRUCTWSFPREVIOUSVERSION"/"

sudo mkdir upgrade

cd upgrade

cecho "\n\nDownload structWSF...\n"

sudo wget $STRUCTWSFDOWNLOADURL  

cecho "\n\nDecompressing structWSF...\n"

sudo unzip "structWSF-v"$STRUCTWSFVERSION".zip"  

cd `ls -d structureddynamics*/`

sudo mv -f * ../

cd ../

sudo rm -rf `ls -d structureddynamics*/`

cecho "\n\nRemove default settings in the new version...\n"

sudo rm data.ini
sudo rm network.ini
sudo rm index.php
sudo rm auth/wsf_indexer.php
sudo rm scones/config.ini
sudo rm "structWSF-v$STRUCTWSFVERSION.zip"

cecho "\n\nMove new files to the current structWSF installation folder...\n"

sudo cp -af * $STRUCTWSFFOLDER"/"

#
# These are the steps that needs to be performed for each upgrade.
# Some of these steps may not apply to a specific version upgrade
# in which case it will simply be ignored.
#

# 1) Delete files in the previous version of structWSF that are not needed anymore
# 2) If the WebService.php file got modified, do re-create it using the same $data_ini and $network_ini settings

cecho "\n\nUpgrade WebService.php while keeping previous configs in it...\n"

sudo sed -i 's>public static $data_ini = "/data/";>public static $data_ini = "'$DATA_INI'";>' $STRUCTWSFFOLDER"/framework/WebService.php"
sudo sed -i 's>public static $network_ini = "/usr/share/structwsf/";>public static $network_ini = "'$NETWORK_INI'";>' $STRUCTWSFFOLDER"/framework/WebService.php"

# 3) If new data.ini settings got added, add them to the end of the current data.ini file
# 4) If new network.ini settings got added, add them to the end of the current network.ini file
# 5) If changes have been made to the Triple Store, do perform these changes
# 6) If the Solr schema changed, instruct the user what to do (upgrading the schema, and then reloading its data)
# 7) If new software or libraries are needed for this upgrade, then simply install and configure them.
# 8) Delete deprecated files

cd ..
rm -rf upgrade

cecho "\n\nThe files of the previous version are still available in that folder: /tmp/structWSF-backup-"$STRUCTWSFPREVIOUSVERSION"/\n" $green

