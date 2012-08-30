#!/bin/bash

STRUCTWSFVERSION="1.1.0"
STRUCTWSFFOLDER="/usr/share/structwsf/"

# From: http://ajdiaz.wordpress.com/2008/02/09/bash-ini-parser/
cfg_parser ()
{
    ini="$(<$1)"                # read the file
    ini="${ini//[/\[}"          # escape [
    ini="${ini//]/\]}"          # escape ]
    IFS=$'\n' && ini=( ${ini} ) # convert to line-array
    ini=( ${ini[*]//;*/} )      # remove comments with ;
    ini=( ${ini[*]/\    =/=} )  # remove tabs before =
    ini=( ${ini[*]/=\   /=} )   # remove tabs be =
    ini=( ${ini[*]/\ =\ /=} )   # remove anything with a space around =
    ini=( ${ini[*]/#\\[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%\\]/ \(} )    # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )    # convert item to array
    ini=( ${ini[*]/%/ \)} )     # close array parenthesis
    ini=( ${ini[*]/%\\ \)/ \\} ) # the multiline trick
    ini=( ${ini[*]/%\( \)/\(\) \{} ) # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} ) # remove extra parenthesis
    ini[0]="" # remove first element
    ini[${#ini[*]} + 1]='}'    # add the last brace
    eval "$(echo "${ini[*]}")" # eval the result
}
 
cfg_writer ()
{
    IFS=' '$'\n'
    fun="$(declare -F)"
    fun="${fun//declare -f/}"
    for f in $fun; do
        [ "${f#cfg.section}" == "${f}" ] && continue
        item="$(declare -f ${f})"
        item="${item##*\{}"
        item="${item%\}}"
        item="${item//=*;/}"
        vars="${item//=*/}"
        eval $f
        echo "[${f#cfg.section.}]"
        for var in $vars; do
            echo $var=\"${!var}\"
        done
    done
}

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

echo -e "\n\n"
cecho "----------" 
cecho " Welcome! "
cecho "----------"
echo -e "\n\n"

cecho "You are about to upgrade structWSF on your system..\n"

cecho "  -> Everything that appears in **cyan** in the installation process, are important remarks and things to consider" $cyan
cecho "  -> Everything that appears in **purple** in the installation process, are questions requested by the installation manual." $magenta
cecho "  -> Everything that appears in **white** in the installation process, are processed undertaken by the installation script." $green
cecho "  -> Everything that appears in **green** in the installation process, are processes that successfully ended." $green
cecho "  -> Everything that appears in **yellow** in the installation process, are things that may have gone wrong and that needs investigation." $yellow
cecho "  -> Everything that appears in **red** in the installation process, are things that goes wrong and that needs immediate investigation in order to OSF to operate normally." $red
echo "  -> Everything else are processed ran by the installation script but that are performed by external installation programs and scripts."
cecho "\n\nCopyright 2008-12. Structured Dynamics LLC. All rights reserved.\n\n"

echo -e "\n\n"
cecho "---------------------"
cecho " Upgrading structWSF "
cecho "---------------------"
echo -e "\n\n"

cecho "What is the new version of structWSF you want to install (latest: $STRUCTWSFVERSION):" $magenta

read NEWSTRUCTWSFVERSION

[ -n "$NEWSTRUCTWSFVERSION" ] && STRUCTWSFVERSION=$NEWSTRUCTWSFVERSION

cecho "Where is located your current installation of structWSF (default: $STRUCTWSFFOLDER):" $magenta

read NEWSTRUCTWSFFOLDER

[ -n "$NEWSTRUCTWSFFOLDER" ] && STRUCTWSFFOLDER=$NEWSTRUCTWSFFOLDER

# Make sure there is no trailing slashes
STRUCTWSFFOLDER=$(echo "${STRUCTWSFFOLDER}" | sed -e "s/\/*$//")


# Read the version of the currently installed structWSF version

if [ -d "$STRUCTWSFFOLDER" ]; then
  cfg_parser $STRUCTWSFFOLDER"/VERSION.ini"
else
  cecho "The structWSF Folder you provided is not existing on this system. Quitting..." $red
  exit
fi

cfg.section.version

CURRENTSTRUCTWSFVERSION=$version

# Parse the versions file.

cfg_parser "versions/versions.ini"

# Parse the section for the current version of structWSF

# Check if the current version is up-to-date

cfg.section.$CURRENTSTRUCTWSFVERSION

if [[ $nextVersion = "none" ]]
then
  cecho "Your structWSF version is already up-to-date" $cyan
  exit 0
fi

UPGRADEVERSIONS=1

while [ $UPGRADEVERSIONS = 1 ]; do

  cecho "Upgrade to version: "$nextVersion

  cfg.section.$nextVersion
  
  if [[ $updateScript != "" ]]
  then
    chmod 755 "versions/"$updateScript
    "versions/"$updateScript $STRUCTWSFFOLDER
  fi

  if [[ $nextVersion = none || $CURRENTSTRUCTWSFVERSION = $STRUCTWSFVERSION ]]
  then
    UPGRADEVERSIONS=0
  fi  
  
  CURRENTSTRUCTWSFVERSION=$nextVersion
  
done 

cecho "structWSF successfully upgraded to version $STRUCTWSFVERSION" $green


