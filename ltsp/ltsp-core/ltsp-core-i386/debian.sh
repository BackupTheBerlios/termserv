#! /bin/sh
#
# Copyright (c) 2000 by James A. McQuillan (McQuillan Systems)
# Copyright (c) 2000 by Stephan Lauffer
# Copyright (c) 2000 by Georg Baum
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# MCQUILLAN SYSTEMS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
# OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# 05/09/2002 -Georg Baum- minor fixes, support for dhcp3-server
# 11/28/2001 -Jim McQuillan- Updated version to 3.0.0
#
# 09/16/2001 -Jim McQuillan- Updated for LTSP 2.09pre2
# 07/09/2001 -Georg Baum- fixes for different nfs server packages and Debian 3.0
# 12/31/2000 -Georg Baum- minor fixes for ltsp version 2.05
# 10/26/2000 -Georg Baum- first version for Debian
# 08/10/2000 -Jim McQuillan- Updated for ltsp version 2.01
# 08/09/2000 -Stephan Lauffer - minor updates and changes
#             for "multi-distribution support"
# 08/05/2000 -Jim McQuillan- Updated for ltsp version 2.0
# 02/13/2000 -Jim McQuillan- New script to build
#             an LTSP environment on a server
#
##############################################################################


##############################################################################
#
# Read the global settings... and set some other stuff...
#

. ./CONFIG

#
# we support several displaymanagers. No matter which one is used, we install
# our own files (Xsetup_workstation and ltsp.gif) into the xdm directory, 
# because that simplifies the handling a bit. 
#
# X_DISPLAYMANAGERS is the list of supported displaymanagers. If you make any 
# changes here, make sure that the code below which sets up TARGET_XACCESS, 
# TARGET_XSERVERS, TARGET_XDM_CONFIG and TARGET_INITTAB still works.
# The order is important, since in case there is more than one dm installed
# and none running, the first one wins!
#
X_DISPLAYMANAGERS="xdm kdm gdm wdm"

#
# try to find out if a dm is running
#
DM_RUNNING=no
for i in ${X_DISPLAYMANAGERS}
do

#
# if there is a rc.d link for a dm, we assume the dm is installed and running.
# This is not perfect, but does anybody know a better way?
#
    if ls /etc/rc0.d | grep K..$i >/dev/null 2>&1; then
	DM_RUNNING=yes
	break
    fi
done

# In case kdm is installed, find out what version, because the configuration
# files changed between 2.1 and 2.2.
#
if test -e /etc/kde3/kdm; then
    KDE_VERSION="3"
    KDM_DIR="/etc/kde3/kdm"
elif test -e /etc/kde2/kdm; then
    KDE_VERSION="2.2"
    KDM_DIR="/etc/kde2/kdm"
else
    KDE_VERSION="< 2.2"
    KDM_DIR="/etc/X11/kdm"
fi
#
##############################################################################

##############################################################################
#
# Read functions...
#
. ./install_functions.sh

# prevent logit() from rotating the logfile once more, since this was already
# done by install.sh
export LOGINIT="Y"
#
##############################################################################

##############################################################################
#
# One additional Debian-specific function
#
function version_warn(){
#
# syntax: version_warn debian_name debian_version [old|new]
# if old is given, the version of debian we are running on is very old and 
# this script has not been fully tested on that version
# if new is given, the version of debian we are running on is possibly newer
# than this script.
#
    if test "$3" = "old"; then
        echo "Warning: Your version of Debian GNU/Linux is '$2'." 
        echo "         This version is very old and this version of LTSP has not been"
	echo "         fully tested with Debian GNU/Linux $2."
	echo "         You should consider upgrading to a newer Debian release."
    elif test "$3" = "new"; then
        echo "Warning: Your version of Debian GNU/Linux is named '$1'." 
        echo "         This version was not yet released stable by the time this version"
	echo "         of LTSP was created. It is possible that not everything"
	echo "         works as expected."
    else
        echo "Warning: Your version of Debian GNU/Linux is named '$1'." 
        echo "         This version was released as Debian GNU/Linux $2,"
        echo "         but you may have a pre-release version."
    fi
    echo "         Please check the generated template files carefully, since they"
    echo "         might not work well with your version of Debian GNU/Linux."
}
#
##############################################################################

##############################################################################
#
# We check what's the name of this file. I want to offer a way to use 
# different sysmlinks to this file which helps us to change some
# stuff if necessary... 
#
SCRIPT_NAME=`basename $0`
VERSION=`echo $0 | sed 's/\.sh//g' | cut -s -f2 -d-`

#
# Here we have to do some tests. The release policy of Debian is that a version
# number is only assigned to stable releases. Until a distribution is released
# as stable, it has no version number but a codename. So we have to check if
# we are running on an unstable version, because something could be broken
# on the particular snapshot the user has.
# If we are running on an unstable version, a warning is issued.
#
if test "${VERSION}" = "hamm"; then
    VERSION_MAJOR=2
    VERSION_MINOR=0
    version_warn ${VERSION} ${VERSION_MAJOR}.${VERSION_MINOR}
elif test "${VERSION}" = "slink"; then
    VERSION_MAJOR=2
    VERSION_MINOR=1
    version_warn ${VERSION} ${VERSION_MAJOR}.${VERSION_MINOR}
elif test "${VERSION}" = "potato"; then
    VERSION_MAJOR=2
    VERSION_MINOR=2
    version_warn ${VERSION} ${VERSION_MAJOR}.${VERSION_MINOR}
elif test "${VERSION}" = "woody"; then
    VERSION_MAJOR=3
    VERSION_MINOR=0
    version_warn ${VERSION} ${VERSION_MAJOR}.${VERSION_MINOR}
elif test "${VERSION}" = "testing_unstable"; then
    # This can be any release after potato. For now (until woody is released)
    # we can safely treat is as woody, but this may change once
    # woody is released and we have a new testing distribution.
    # we give it a chance but warn the user that it might fail.
    VERSION_MAJOR=3
    VERSION_MINOR=0
    version_warn "testing/unstable" ${VERSION_MAJOR}.${VERSION_MINOR}
elif test "${VERSION}" = "unstable"; then
    # This can be any release after potato. For now (until woody is released)
    # we can safely treat is as woody, but this may change once
    # woody is released and we have a new unstable distribution.
    # we give it a chance but warn the user that it might fail.
    VERSION_MAJOR=3
    VERSION_MINOR=0
    version_warn ${VERSION} ${VERSION_MAJOR}.${VERSION_MINOR} new
else
    VERSION_MAJOR=`echo ${VERSION} | cut -s -f1 -d.`
    VERSION_MINOR=`echo ${VERSION} | cut -s -f2 -d.`
fi

#
# I could only test very briefly Debian GNU/Linux 2.0, so issue a 
# warning here. If the user uses an unstable 2.0 (hamm), he gets
# two warnings, but since this is a very old release (Aug 1998),
# he should upgrade anyway.
#
if test "${VERSION_MAJOR}" = "2" -a "${VERSION_MINOR}" = "0"; then
    version_warn hamm ${VERSION_MAJOR}.${VERSION_MINOR} old
fi

#
# refuse to run on unknown versions
# maybe add a --force VERSION=x.y commandline option?
#
if ! test "${VERSION_MAJOR}" = "2" -a \
           ${VERSION_MINOR} -ge 0 -a ${VERSION_MINOR} -le 2 -o \
          "${VERSION_MAJOR}" = "3" -a "${VERSION_MINOR}" = "0"; then
    echo "Error: Debian GNU/Linux ${VERSION} not supported."
    exit 1
fi
#
#############################################################################

##############################################################################
#
# Create the templates for the files listed in the SOURCE_* variables above
#
# We will place them in ${TMPL_DIR}, so that a sysadmin can
# review them before putting them in place.
#
# We build a bunch of small shell scripts to do the work.  The sysadmin
# can then take a look at the scripts and modify them if they like, before
# executing them with the ltsp_initialize script
#

#------------------------------------------------------------------------------
#
# Create an updated /etc/exports file
#
# If the current exports file does not contain any mention
# of ltsp, then we can just add the new entries to the end.
# If it does contain entries from a previous ltsp installation,
# then we need to save the file and create a new one.
#
SOURCE=/etc/exports
TARGET=${TMPL_DIR}/exports.tmpl
logit "Setting up ${TARGET}"

(
    echo ":"
    echo "#"
    echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
    echo "#"
    echo "# This file was taken from this server and modified to contain "
    echo "# entries for an LTSP workstation."
    echo "#"
    echo "# This shell script is normally run by the ltsp_initialize script."
    echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
    echo "# and place them where the TARGET variable is pointing to."
    echo "#"
    echo ""
    echo "TARGET=${SOURCE}"
    echo "DEFAULT=Y"
    echo "DESCRIPTION=\"The config file for nfs\""
    echo "DESC_KEY=exports"
    echo ""
    echo 'if [ -f ${TARGET} ]; then'
    echo '    FILENUM=1'
    echo '    while :; do'
    echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
    echo '            FILENUM=`expr ${FILENUM} + 1`'
    echo '        else'
    echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
    echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
    echo '            break'
    echo '        fi'
    echo '    done'
    echo 'fi'
    echo ""
    echo 'cat <<EOF >${TARGET}'
) >${TARGET}

#
# If the /etc/exports file already exists, then we will get a copy of it,
# stripping out the original LTSP stuff.  This needs to be better, it should
# actually preserve the existing LTSP stuff.
#
if [ -f ${SOURCE} ]; then
    logit "Using original ${SOURCE} file as the base"
    sed '/## LTS-begin ##/,/## LTS-end ##/d' <${SOURCE} >>${TARGET}
fi

(
    echo "## LTS-begin ##"
    echo
    echo "#"
    echo "# The lines between the 'LTS-begin' and the 'LTS-end' were added"
    echo "# on: ${TODAY} by the ltsp installation script."
    echo "# For more information, visit the ltsp homepage"
    echo "# at http://www.ltsp.org"
    echo "#"
    echo
    echo "${ROOT_DIR}                  ${IP_NETWORK}/${IP_NETMASK}(ro,no_root_squash)"
    echo "${SWAP_DIR}         ${IP_NETWORK}/${IP_NETMASK}(rw,no_root_squash)"
    echo
    echo "#"
    echo "# The following entries need to be uncommented if you want"
    echo "# Local App support in ltsp"
    echo "#"
    echo "#/home                  ${IP_NETWORK}/${IP_NETMASK}(rw,no_root_squash)"
    echo
    echo "## LTS-end ##"
) >>${TARGET}

(
    echo "EOF"
    echo ""
    echo 'chmod 0644 ${TARGET}'
) >>${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Display Managers
#
# There are several to choose from.  Debian usually ships with
# xdm, kdm, wdm and gdm.
# While xdm, kdm (until kde 2.1) and wdm all have the same config files (but in
# different directories), gdm and partly kdm (kde 2.2 and above) use a
# completely different scheme.
#
# We are going to setup all of them, in case the sysadm wants to
# change which display manager is being used.
#

#------------------------------------------------------------------------------
#
# Update the /etc/X11/${DM}/xdm-config file
#
# If the current xdm-config file does not contain any mention
# of ltsp, then we can just add the new entries to the end.
# If it does contain entries from a previous ltsp installation,
# then we need to save the file and create a new one.
#
for DM in ${X_DISPLAYMANAGERS}
do
    if test "${DM}" != "gdm" -a \( "${DM}" = "kdm" -a -d "${KDM_DIR}" -a \( "${KDE_VERSION}" = "< 2.2" -o "${KDE_VERSION}" = "2.2" \) -o -d /etc/X11/${DM} \); then
	if test "${DM}" = "wdm"; then
    	    SOURCE=/etc/X11/${DM}/${DM}-config
        elif test "${DM}" = "kdm"; then
	    if test "${KDE_VERSION}" = "< 2.2"; then
    		SOURCE=/etc/X11/${DM}/xdm-config
    	    else
        	SOURCE=${KDM_DIR}/${DM}-config
	    fi
	else
    	    SOURCE=/etc/X11/${DM}/xdm-config
	fi
        TARGET=${TMPL_DIR}/${DM}-config.tmpl

        logit "Setting up ${TARGET}"

        (
            echo ":"
            echo "#"
            echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
            echo "#"
            echo "# This file was taken from this server and modified to setup "
            echo "# a workstation Startup script for an LTSP workstation"
            echo "#"
            echo "# This shell script is normally run by the ltsp_initialize script."
            echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
            echo "# and place them where the TARGET variable is pointing to."
            echo "#"
            echo ""
            echo "TARGET=${SOURCE}"
            echo "DEFAULT=Y"
            echo "DESCRIPTION=\"The main config file for ${DM}\""
            echo "DESC_KEY=${DM}-config"
            echo ""
            echo 'if [ -f ${TARGET} ]; then'
            echo '    FILENUM=1'
            echo '    while :; do'
            echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
            echo '            FILENUM=`expr ${FILENUM} + 1`'
            echo '        else'
            echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
            echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
            echo '            break'
            echo '        fi'
            echo '    done'
            echo 'fi'
            echo ""
            echo "cat <<'EOF' >\${TARGET}"
        ) >${TARGET}

        #
        # If the /etc/X11/${DM}/xdm-config file already exists, then we will get a 
        # copy of it, stripping out the original LTSP stuff.  This needs to be better, 
        # it should actually preserve the existing LTSP stuff.
        #
        if [ -f ${SOURCE} ]; then
            logit "Using original ${SOURCE} file as the base"
	    sed 's/^DisplayManager\.requestPort/! DisplayManager.requestPort/
		 s/\(^DisplayManager\.\{0,1\}\*\.\{0,1\}setup\)/! \1/
	    /## LTS-begin ##/,/## LTS-end ##/d
	    ' <${SOURCE} >>${TARGET}
        fi

        (
            echo "## LTS-begin ##"
            echo
            echo "#"
            echo "# The lines between the 'LTS-begin' and the 'LTS-end' were added"
            echo "# on: ${TODAY} by the ltsp installation script."
            echo "# For more information, visit the ltsp homepage"
            echo "# at http://www.ltsp.org"
            echo "#"
            echo
            echo "DisplayManager.*.setup:     /etc/X11/xdm/Xsetup_workstation"
            echo
	    echo "## LTS-end ##"
	    echo "EOF"
            echo ""
            echo 'chmod 0444 ${TARGET}'
        ) >>${TARGET}

        chmod 0644      ${TARGET}
        chown root:root ${TARGET}
    fi
done

#------------------------------------------------------------------------------
#
# Create the /etc/X11/xdm/Xsetup_workstation file
#
# If there is already an Xsetup_workstation file, save it
#
SOURCE=/etc/X11/xdm/Xsetup_workstation
TARGET=${TMPL_DIR}/Xsetup_workstation.tmpl

logit "Setting up ${TARGET}"

(
    echo ":"
    echo "#"
    echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
    echo "#"
    echo "# This file created fresh to setup "
    echo "# a workstation startup script for an LTSP workstation"
    echo "#"
    echo "# This shell script is normally run by the ltsp_initialize script."
    echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
    echo "# and place them where the TARGET variable is pointing to."
    echo "#"
    echo ""
    echo "TARGET=${SOURCE}"
    echo 'TARGET_DIR=`dirname ${TARGET}`'
    echo "DEFAULT=Y"
    echo "DESCRIPTION=\"Sets the logo of your login window\""
    echo "DESC_KEY=Xsetup_workstation"
    echo ""
    echo 'if [ -f ${TARGET} ]; then'
    echo '    FILENUM=1'
    echo '    while :; do'
    echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
    echo '            FILENUM=`expr ${FILENUM} + 1`'
    echo '        else'
    echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
    echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
    echo '            break'
    echo '        fi'
    echo '    done'
    echo 'fi'
    echo ""
    echo '# If the directory ${TARGET_DIR} does not exist, create it.'
    echo "# This is possible if xdm was never installed on this machine."
    echo '# We put Xsetup_workstation in ${TARGET_DIR} regardless of the'
    echo "# used displaymanager in order to avoid multiple copies."
    echo ""
    echo 'test -d ${TARGET_DIR} || mkdir -p ${TARGET_DIR}'
    echo ""
    echo "cat <<'EOF' >\${TARGET}"
) >${TARGET}

(
    echo "## LTS-begin ##"
    echo
    echo "#"
    echo "# The lines between the 'LTS-begin' and the 'LTS-end' were added"
    echo "# on: ${TODAY} by the ltsp installation script."
    echo "# For more information, visit the ltsp homepage"
    echo "# at http://www.ltsp.org"
    echo "#"
    echo
    echo '/usr/X11R6/bin/xsetroot -solid "#356390"'
    echo 'if [ -x /usr/bin/xsri ]; then'
    echo '    /usr/bin/xsri -geometry +5+5 -avoid 300x250 -keep-aspect \'
    echo '        /etc/X11/xdm/ltsp.gif'
    echo 'fi'
    echo
    echo "## LTS-end ##"
) >>${TARGET}

(
    echo "EOF"
    echo ""
    echo 'chmod 0755 ${TARGET}'
) >>${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Modify the /etc/X11/xdm/Xservers file
#

#
# If ${DM_RUNNING} = yes then they are already
# running a display manager, so we don't want to change
# the Xservers file, because that would disable X on the console.
# If they are ${DM_RUNNING} = no, then we should comment out the
# line in this file, so that X doesn't startup on the console
# automatically later when we start the display manager.
#

for DM in ${X_DISPLAYMANAGERS}
do

    if test "${DM}" != "gdm" -a "${DM_RUNNING}" = "no"; then

        if test "${DM}" = "kdm"; then
            SOURCE=${KDM_DIR}/Xservers
        else
            SOURCE=/etc/X11/${DM}/Xservers
        fi
        TARGET=${TMPL_DIR}/${DM}_Xservers.tmpl
        logit "Setting up ${TARGET}"

        (
            echo ":"
            echo "#"
            echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
            echo "#"
            echo "# This file was taken from this server and modified to either"
            echo "# enable or disable the GUI login on the console, depending"
            echo "# wether ${DM} was already running or not."
            echo "#"
            echo "# This shell script is normally run by the ltsp_initialize script."
            echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
            echo "# and place them where the TARGET variable is pointing to."
            echo "#"
            echo ""
            echo "TARGET=${SOURCE}"
            echo "DEFAULT=Y"
            echo "DESCRIPTION=\"Config to ${DM} to launch local Xserver\""
            echo "DESC_KEY=Xservers"
            echo ""
            echo 'if [ -f ${TARGET} ]; then'
            echo '    FILENUM=1'
            echo '    while :; do'
            echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
            echo '            FILENUM=`expr ${FILENUM} + 1`'
            echo '        else'
            echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
            echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
            echo '            break'
            echo '        fi'
            echo '    done'
            echo 'fi'
            echo ""
            echo "cat <<'EOF' >\${TARGET}"
        ) >${TARGET}

        if [ -f ${SOURCE} ]; then
            logit "Using original ${SOURCE} file as the base"
	    sed 's/^:0/# :0/' <${SOURCE} >>${TARGET}
    	    (
        	echo "#"
        	echo "# The above line for starting an X server on display :0"
        	echo "# was commented out on: ${TODAY} by the ltsp installation"
        	echo "# script."
        	echo "# For more information, visit the ltsp homepage"
        	echo "# at http://www.ltsp.org"
        	echo "#"
    	    ) >>${TARGET}
	fi

        (
            echo "EOF"
            echo ""
            echo 'chmod 0444 ${TARGET}'
        ) >>${TARGET}

        chmod 0644      ${TARGET}
        chown root:root ${TARGET}
    fi
done

#------------------------------------------------------------------------------
#
# Copy the ltsp.gif logo file
#
SOURCE=${TMPL_DIR}/ltsp.gif
DEST=/etc/X11/xdm/ltsp.gif
TARGET=${TMPL_DIR}/ltsplogo.tmpl

logit "Setting up ${TARGET}"

(
    echo ":"
    echo "#"
    echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
    echo "#"
    echo "# This file created fresh to setup "
    echo "# a workstation startup script for an LTSP workstation"
    echo "#"
    echo "# This shell script is normally run by the ltsp_initialize script."
    echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
    echo "# and place them where the TARGET variable is pointing to."
    echo "#"
    echo ""
    echo "SOURCE=${SOURCE}"
    echo "TARGET=${DEST}"
    echo 'TARGET_DIR=`dirname ${TARGET}`'
    echo "DEFAULT=Y"
    echo "DESCRIPTION=\"The logo picture for your login screen\""
    echo "DESC_KEY=ltsp.gif"
    echo ""
    echo 'if [ -f ${TARGET} ]; then'
    echo '    FILENUM=1'
    echo '    while :; do'
    echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
    echo '            FILENUM=`expr ${FILENUM} + 1`'
    echo '        else'
    echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
    echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
    echo '            break'
    echo '        fi'
    echo '    done'
    echo 'fi'
    echo ""
    echo '# If the directory ${TARGET_DIR} does not exist, create it.'
    echo "# This is possible if xdm was never installed on this machine."
    echo '# We put ltsp.gif in ${TARGET_DIR} regardless of the'
    echo "# used displaymanager in order to avoid multiple copies."
    echo ""
    echo 'test -d ${TARGET_DIR} || mkdir -p ${TARGET_DIR}'
    echo ""
) >${TARGET}

echo 'cp ${SOURCE}    ${TARGET}' >>${TARGET}

(
    echo ""
    echo 'chmod 0644 ${TARGET}'
) >>${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}
#------------------------------------------------------------------------------
#
# Modify the /etc/X11/xdm/Xaccess file
#
# If the current Xaccess file does not contain any mention
# of ltsp, then we can just add the new entries to the end.
# If it does contain entries from a previous ltsp installation,
# then we need to save the file and create a new one.
#
for DM in ${X_DISPLAYMANAGERS}
do

    #
    # kdm 1.x and wdm go the xdm way, but gdm and newer versions of kdm have their own configuration file syntax.
    #
    if test "${DM}" != "gdm" -a \( "${DM}" = "kdm" -a -d ${KDM_DIR} -o -d /etc/X11/${DM} \); then
        if test "${DM}" = "kdm" -a "${KDE_VERSION}" != "< 2.2"; then
            if grep "^Xaccess=" ${KDM_DIR}/kdmrc > /dev/null 2>&1; then
                SOURCE=`grep "^Xaccess=" ${KDM_DIR}/kdmrc | cut -d= -f2`
            else
                SOURCE=${KDM_DIR}/Xaccess
            fi
        else
            SOURCE=/etc/X11/${DM}/Xaccess
        fi
        TARGET=${TMPL_DIR}/${DM}_Xaccess.tmpl
        logit "Setting up ${TARGET}"

        (
            echo ":"
            echo "#"
            echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
            echo "#"
            echo "# This file was taken from this server and modified to allow remote "
            echo "# X terminals to get an ${XDM} login prompt"
            echo "#"
            echo "# This shell script is normally run by the ltsp_initialize script."
            echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
            echo "# and place them where the TARGET variable is pointing to."
            echo "#"
            echo ""
            echo "TARGET=${SOURCE}"
            echo "DEFAULT=Y"
            echo "DESCRIPTION=\"The access config file for ${DM}\""
            echo "DESC_KEY=Xaccess"
            echo ""
            echo 'if [ -f ${TARGET} ]; then'
            echo '    FILENUM=1'
            echo '    while :; do'
            echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
            echo '            FILENUM=`expr ${FILENUM} + 1`'
            echo '        else'
            echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
            echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
            echo '            break'
            echo '        fi'
            echo '    done'
            echo 'fi'
            echo ""
            echo "cat <<'EOF' >\${TARGET}"
        ) >${TARGET}


        #
        # If the /etc/X11/${DM}/Xaccess file already exists, then we will get a
        # copy of it, stripping out the original LTSP stuff.  This needs to be better, 
        # it should actually preserve the existing LTSP stuff.
        #
        if [ -f ${SOURCE} ]; then
    	    sed 's/^# \*/\*/
		/## LTS-begin ##/,/## LTS-end ##/d' <${SOURCE} >>${TARGET}
        else
            (
                echo "## LTS-begin ##"
                echo
                echo "#"
                echo "# The lines between the 'LTS-begin' and the 'LTS-end' were added"
                echo "# on: ${TODAY} by the ltsp installation script."
                echo "# For more information, visit the ltsp homepage"
                echo "# at http://www.ltsp.org"
                echo "#"
                echo
    		echo "*          #any host can get a login window" >>${TARGET}
                echo
                echo "## LTS-end ##"
    	    ) >>${TARGET}
        fi

        (
            echo "EOF"
            echo ""
            echo 'chmod 0444 ${TARGET}'
        ) >>${TARGET}

        chmod 0644      ${TARGET}
        chown root:root ${TARGET}
    fi
done

#------------------------------------------------------------------------------
#
# Modify the ${KDM_DIR}/kdmrc file
# From kde 2.2 on, kdm does not use most of the xdm compatible files anymore.
# Instead, it stores everything in the file kdmrc.
#
# If the current kdmrc file does not contain any mention
# of ltsp, then we can just add the new entries to the end.
# If it does contain entries from a previous ltsp installation,
# then we need to save the file and create a new one.
#
    
if [ "${KDE_VERSION}" != "< 2.2" -a -d ${KDM_DIR} ]; then
    
    SOURCE=${KDM_DIR}/kdmrc
    TARGET=${TMPL_DIR}/kdmrc.tmpl
    logit "Setting up ${TARGET}"
    
    (
        echo ":"
        echo "#"
        echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
        echo "#"
        echo "# This shell script is normally run by the ltsp_initialize script."
        echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
        echo "# and place them where the TARGET variable is pointing to."
        echo "#"
        echo ""
        echo "TARGET=${SOURCE}"
        echo "DEFAULT=Y"
        echo "DESCRIPTION=\"The configuration file for kdm (K Display Manager)\""
        echo "DESC_KEY=kdmrc"
        echo ""
        echo 'if [ -f ${TARGET} ]; then'
        echo '    FILENUM=1'
        echo '    while :; do'
        echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
        echo '            FILENUM=`expr ${FILENUM} + 1`'
        echo '        else'
        echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
        echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
        echo '            break'
        echo '        fi'
        echo '    done'
        echo 'fi'
        echo ""
        echo "cat <<'EOF' >\${TARGET}"
    ) >${TARGET}
    
    #
    # If the /etc/kde2/kdm/kdm.conf file already exists, then we will get a
    # copy of it, stripping out the original LTSP stuff.  This needs to be better, 
    # it should actually preserve the existing LTSP stuff.
    #
    # Todo: the begin- and end lines are not added yet by kdm-change.pl!
    #
    if [ -f ${SOURCE} ]; then
        if test "${DM_RUNNING}" = "yes"; then
            ./kdm-change.pl < ${SOURCE} | sed \
		'/## LTS-begin ##/,/## LTS-end ##/d' >>${TARGET}
        else
            ./kdm-change.pl < ${SOURCE} | sed 's/^0=/# 0=/g
		/## LTS-begin ##/,/## LTS-end ##/d' >>${TARGET}
        fi
    else
	(
	    echo "## LTS-begin ##"
    	    echo
    	    echo "#"
    	    echo "# The lines between the 'LTS-begin' and the 'LTS-end' were added"
    	    echo "# on: ${TODAY} by the ltsp installation script."
    	    echo "# For more information, visit the ltsp homepage"
    	    echo "# at http://www.ltsp.org"
    	    echo "#"
    	    echo
	) >>${TARGET}
	if test "${KDE_VERSION}" != "< 2.2" -a "${KDE_VERSION}" != "2.2" ; then
	    (
    	    	echo '[X-*-Core]' 
    	    	echo 'Setup=/etc/X11/xdm/Xsetup_workstation'
    	    	echo
    	    	echo '[X-:*-Core]' 
    	    	echo "Setup=${KDM_DIR}/Xsetup"
    	    	echo
	    ) >>${TARGET}
	fi
	(
    	    echo '[Xdmcp]'
	    echo 'Enable=true'
    	    echo
    	    echo "## LTS-end ##"
	) >>${TARGET}
    fi
    
    (
        echo "EOF"
        echo ""
        echo 'chmod 0444 ${TARGET}'
    ) >>${TARGET}

    chmod 0644      ${TARGET}
    chown root:root ${TARGET}
    
fi


################################################################################
#
#    #####  ######  #     #
#   #     # #     # ##   ##
#   #       #     # # # # #
#   #  #### #     # #  #  #
#   #     # #     # #     #
#   #     # #     # #     #
#    #####  ######  #     #
#
#------------------------------------------------------------------------------
#
# Update the /etc/X11/gdm/Init/Default file
#
# When gdm detects an Xserver contacting it for a login,
# it looks in the /etc/X11/gdm/Init directory for a file
# that matches the value of the $DISPLAY environment variable.
# For instance, the Xserver running on the server would have
# a DISPLAY variable set to ':0', so gdm will look for a file
# called '/etc/X11/gdm/Init/:0'.  If it doesn't find that file
# then it will look for a file called '/etc/X11/gdm/Init/Default'
# and use that instead.
#
# Our ltsp configuration script will rename 'Default' to ':0'
# so that the Xserver running on the console will continue to
# appear the same.
#
# To handle the workstations, we will create a new symlink
# called 'Default' and point it to /etc/X11/xdm/Xsetup_workstation
#
if [ -d /etc/X11/gdm ]; then
    SOURCE=/etc/X11/gdm/Init/Default
    TARGET=${TMPL_DIR}/gdm_Init_Default.tmpl
    
    if [ -d /etc/X11/gdm/Init ]; then
        (
            echo ":"
            echo "#"
            echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
            echo "#"
            echo "# This shell script is normally run by the ltsp_initialize script."
            echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
            echo "# and place them where the TARGET variable is pointing to."
            echo "#"
            echo ""
            echo "TARGET=${SOURCE}"
            echo "DEFAULT=Y"
            echo "DESCRIPTION=\"The gdm startup script\""
            echo "DESC_KEY=gdm_Init_Default"
    
            echo ""
            echo "# If there was already a :0 file, then leave it alone"
            echo "# Normally, we will rename the Default file to :0, unless"
            echo "# a :0 file already exists, in which case, we will leave the "
            echo "# :0 file alone and remove the Default file"
            echo ""
            echo 'if [ -f ${TARGET} -o -L ${TARGET} ]; then'
            echo ''
            echo '    #'
            echo '    # We have to test -L also, because -f returns false for a symlink'
            echo '    # which points to a nonexistant file.'
            echo '    #'
            echo '    if [ -f /etc/X11/gdm/Init/:0 -o -L /etc/X11/gdm/Init/:0 ]; then'
            echo '        FILENUM=1'
            echo '        while :; do'
            echo '            if [ -f "${TARGET}.${FILENUM}" -o -L ${TARGET}.${FILENUM} ]; then'
            echo '                FILENUM=`expr ${FILENUM} + 1`'
            echo '            else'
            echo '                echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
            echo '                if test -L ${TARGET}; then'
            echo ''
            echo '                    #'
            echo '                    # if the symlink points to a nonexistant file,'
            echo '                    # the mv command will fail, so create a new symlink.'
            echo '                    #'
	    # The readlink program that we use here is available on all Debian systems, because it is tagged essential
            echo '                    ln -sf `readlink ${TARGET}` ${TARGET}.${FILENUM}'
            echo '                    rm -f ${TARGET}'
            echo '                else'
            echo '                    mv ${TARGET} ${TARGET}.${FILENUM}'
            echo '                fi'
            echo '                break'
            echo '            fi'
            echo '        done'
            echo '    else'
            echo '        echo "Saving old ${TARGET} as /etc/X11/gdm/Init/:0"'
            echo '        if test -L ${TARGET}; then'
	    # The readlink program that we use here is available on all Debian systems, because it is tagged essential
            echo '            ln -sf `readlink ${TARGET}` /etc/X11/gdm/Init/:0'
            echo '            rm -f ${TARGET}'
            echo '        else'
            echo '            mv  ${TARGET} /etc/X11/gdm/Init/:0'
            echo '        fi'
            echo '    fi'
            echo 'fi'
            echo ''
            echo '# This has to be absolute since /etc/X11/gdm is a link to /etc/gdm'
            echo 'ln -s /etc/X11/xdm/Xsetup_workstation ${TARGET}'
            echo ''
            echo "cat <<'EOF' >\${TARGET}"
        ) >${TARGET}
    fi
    
    chmod 0644      ${TARGET}
    chown root:root ${TARGET}
    
    #------------------------------------------------------------------------------
    #
    # Modify the /etc/X11/gdm/gdm.conf file
    #
    # If the current gdm.conf file does not contain any mention
    # of ltsp, then we can just add the new entries to the end.
    # If it does contain entries from a previous ltsp installation,
    # then we need to save the file and create a new one.
    #
    
    SOURCE=/etc/X11/gdm/gdm.conf
    TARGET=${TMPL_DIR}/gdm.conf.tmpl
    logit "Setting up ${TARGET}"

    (
        echo ":"
        echo "#"
        echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
        echo "#"
        echo "# This file was taken from this server and modified to allow remote "
        echo "# X terminals to get an ${XDM} login prompt"
        echo "#"
        echo "# This shell script is normally run by the ltsp_initialize script."
        echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
        echo "# and place them where the TARGET variable is pointing to."
        echo "#"
        echo ""
        echo "TARGET=${SOURCE}"
        echo "DEFAULT=Y"
        echo "DESCRIPTION=\"The config file for gdm\""
        echo "DESC_KEY=gdm.conf"
        echo ""
        echo 'if [ -f ${TARGET} ]; then'
        echo '    FILENUM=1'
        echo '    while :; do'
        echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
        echo '            FILENUM=`expr ${FILENUM} + 1`'
        echo '        else'
        echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
        echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
        echo '            break'
        echo '        fi'
        echo '    done'
        echo 'fi'
        echo ""
        echo "cat <<'EOF' >\${TARGET}"
    ) >${TARGET}

    #
    # If the /etc/X11/gdm/gdm.conf file already exists, then we will get a
    # copy of it, stripping out the original LTSP stuff.  This needs to be better, 
    # it should actually preserve the existing LTSP stuff.
    #
    # Todo: the begin- and end lines are not added yet by gdm-change.pl!
    #
    if [ -f ${SOURCE} ]; then
        if test "${DM_RUNNING}" = "yes"; then
            ./gdm-change.pl < ${SOURCE} | sed \
	    '/## LTS-begin ##/,/## LTS-end ##/d' >>${TARGET}
        else
            ./gdm-change.pl < ${SOURCE} | sed 's/^0=/# 0=/g
	    /## LTS-begin ##/,/## LTS-end ##/d' >>${TARGET}
        fi
    else
    (
	echo "## LTS-begin ##"
    	echo
    	echo "#"
    	echo "# The lines between the 'LTS-begin' and the 'LTS-end' were added"
    	echo "# on: ${TODAY} by the ltsp installation script."
    	echo "# For more information, visit the ltsp homepage"
    	echo "# at http://www.ltsp.org"
    	echo "#"
    	echo
    	echo '[xdmcp]'
    	echo 'Enable=1'
    	echo
        echo "## LTS-end ##"
    ) >>${TARGET}
    fi

    (
        echo "EOF"
        echo ""
        echo 'chmod 0444 ${TARGET}'
        echo ""
    ) >>${TARGET}
    
    chmod 0644      ${TARGET}
    chown root:root ${TARGET}
    
fi
#------------------------------------------------------------------------------
#
# Setup the /etc/hosts.allow file
#
# If the current /etc/hosts.allow file does not contain any mention
# of ltsp, then we can just add the new entries to the end.
# If it does contain entries from a previous ltsp installation,
# then we need to save the file and create a new one.
#
SOURCE=/etc/hosts.allow
TARGET=${TMPL_DIR}/hosts.allow.tmpl
logit "Setting up ${TARGET}"

(
    echo ":"
    echo "#"
    echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
    echo "#"
    echo "# This file was taken from this server and modified to allow"
    echo "# workstations to obtain an IP address via bootp and mount "
    echo "# filesystems via NFS"
    echo "#"
    echo "# This shell script is normally run by the ltsp_initialize script."
    echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
    echo "# and place them where the TARGET variable is pointing to."
    echo "#"
    echo ""
    echo "TARGET=${SOURCE}"
    echo "DEFAULT=Y"
    echo "DESCRIPTION=\"Config file for tcp wrappers\""
    echo "DESC_KEY=hosts.allow"
    echo ""
    echo 'if [ -f ${TARGET} ]; then'
    echo '    FILENUM=1'
    echo '    while :; do'
    echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
    echo '            FILENUM=`expr ${FILENUM} + 1`'
    echo '        else'
    echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
    echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
    echo '            break'
    echo '        fi'
    echo '    done'
    echo 'fi'
    echo ""
    echo "cat <<'EOF' >\${TARGET}"
) >${TARGET}

#
# If the /etc/hosts.allow file already exists, then we will get a
# copy of it, stripping out the original LTSP stuff.  This needs to be better, 
# it should actually preserve the existing LTSP stuff.
#
if [ -f ${SOURCE} ]; then
    logit "Using original ${SOURCE} file as the base"
    sed '/## LTS-begin ##/,/## LTS-end ##/d' <${SOURCE} >>${TARGET}
fi

(
    echo "## LTS-begin ##"
    echo
    echo "#"
    echo "# The lines between the 'LTS-begin' and the 'LTS-end' were added"
    echo "# on: ${TODAY} by the ltsp installation script."
    echo "# For more information, visit the ltsp homepage"
    echo "# at http://www.ltsp.org"
    echo "#"
    echo
    echo "bootpd:    0.0.0.0"
    echo "in.tftpd:  ${IP_NETWORK_BASE}."
    echo "portmap:   ${IP_NETWORK_BASE}."
    echo
    echo "## LTS-end ##"
) >>${TARGET}

(
    echo "EOF"
    echo ""
    echo 'chmod 0644 ${TARGET}'
) >>${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Setup the syslog startup script
#
SOURCE=/etc/init.d/sysklogd
TARGET=${TMPL_DIR}/sysklogd.tmpl
logit "Setting up ${TARGET}"

(
    echo ":"
    echo "#"
    echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
    echo "#"
) >${TARGET}

#
# only if remote syslogging is not enabled, we need to do something
#
if ! grep "^SYSLOGD=" ${SOURCE} | grep -e "-r" >/dev/null; then
    (
        echo "# This file was taken from this server and modified to allow"
        echo "# a remote workstation to send syslog output to this server"
        echo "#"
        echo "# This shell script is normally run by the ltsp_initialize script."
        echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
        echo "# and place them where the TARGET variable is pointing to."
        echo "#"
        echo ""
    ) >>${TARGET}
fi

(
    echo "TARGET=${SOURCE}"
    echo "DEFAULT=Y"
    echo "DESCRIPTION=\"Startup script for the sysklog daemon\""
    echo "DESC_KEY=syslogd"
    echo ""
) >>${TARGET}

if ! grep "^SYSLOGD=" ${SOURCE} | grep -e "-r" >/dev/null; then
    (
        echo 'if [ -f ${TARGET} ]; then'
        echo '    FILENUM=1'
        echo '    while :; do'
        echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
        echo '            FILENUM=`expr ${FILENUM} + 1`'
        echo '        else'
        echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
        echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
        echo '            break'
        echo '        fi'
        echo '    done'
	echo 'fi'
	echo ""
	echo "cat <<'EOF' >\${TARGET}"
    ) >>${TARGET}

    SYSLOGD=""
    OLD_SYSLOGD=`grep '^SYSLOGD=' ${TARGET}`
    eval ${OLD_SYSLOGD}

#
# now ${SYSLOGD} contains the old settings
#
    sed 's/SYSLOGD=.*$/SYSLOGD="'"${SYSLOGD}"' -r"/' \
	<${SOURCE} >>${TARGET}

    (
	echo "EOF"
	echo ""
	echo 'chmod 0755 ${TARGET}'
	echo '/etc/init.d/sysklogd reload > /dev/null 2>&1'
    ) >>${TARGET}
else
    (
        echo "# This shell script is normally run by the ltsp_initialize script."
	echo "#"
	echo "# No changes need to be done, remote syslogging already enabled."
	echo ""
	echo "exit 0"
    ) >>${TARGET}
    logit "${TARGET} unmodified, system already set to allow remote syslogging"
fi

chmod 0644      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Modify the /etc/inetd.conf file
#
SOURCE=/etc/inetd.conf
TARGET=${TMPL_DIR}/inetd.conf.tmpl
logit "Setting up ${TARGET}"

(
    echo ":"
    echo "#"
    echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
    echo "#"
    echo "# This file was taken from this server and modified to allow"
    echo "# tftp to run, so it can serve up kernels for workstations."
    echo "#"
    echo "# This shell script is normally run by the ltsp_initialize script."
    echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
    echo "# and place them where the TARGET variable is pointing to."
    echo "#"
    echo ""
    echo "TARGET=${SOURCE}"
    echo "DEFAULT=Y"
    echo "DESCRIPTION=\"Config file for inetd\""
    echo "DESC_KEY=inetd_tftpd"
    echo ""
    echo 'if [ -f ${TARGET} ]; then'
    echo '    FILENUM=1'
    echo '    while :; do'
    echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
    echo '            FILENUM=`expr ${FILENUM} + 1`'
    echo '        else'
    echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
    echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
    echo '            break'
    echo '        fi'
    echo '    done'
    echo 'fi'
    echo ""
    echo '# Normally, the following line would enable the tftp service.'
    echo '# Unfortunately, this does not work because we also have to change'
    echo '# the tftp directory from /boot to /tftpboot, so we have to copy'
    echo '# the whole file here.'
    echo ''
    echo '# update-inetd --enable tftp'
    echo ''
    echo "cat <<'EOF'>\${TARGET}"
) >${TARGET}

logit "Using original ${SOURCE} file as the base"
if grep '^tftp' ${SOURCE} >/dev/null ; then
    sed 's/\(^tftp.*\)\/boot/\1\/tftpboot/' <${SOURCE} >>${TARGET}
else
    sed 's/\(^#\)\([[:blank:]]*tftp\)/\2/' <${SOURCE} | \
    sed 's/\(^tftp.*\)\/boot/\1\/tftpboot/' >>${TARGET}
fi
(
    echo "EOF"
    echo ""
    echo 'chmod 0644 ${TARGET}'
    echo ""
    echo '# You can either use bootp or dhcp to tell the workstations their'
    echo '# ip-addresses. If you decide to use bootp, you may want to uncomment'
    echo '# the following line:'
    echo '#'
    echo ''
    echo '#    update-inetd --enable bootps'
    echo ''
) >>${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Setup the rc scripts so that ${DM} will start when server boots
#
# If a dm is already running, we don't need to do anything.
# Otherwise, we take the first one of X_DISPLAYMANGERS which is installed.
#
if test "${DM_RUNNING}" = "no"; then
    DM_STARTUP=no
    for DM in ${X_DISPLAYMANAGERS}
    do
        if command -v ${DM} >/dev/null 2>&1; then
            SOURCE=/etc/rc?.d/*${DM}
            TARGET=${TMPL_DIR}/${DM}.tmpl
            logit "Setting up ${TARGET}"

            (
                echo ":"
                echo "#"
                echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
                echo "#"
                echo "# This script will check to see if there is a startup script"
                echo "# to start the ${DM} daemon"
                echo "#"
                echo "# This shell script is normally run by the ltsp_initialize script."
                echo "#"
                echo ""
                echo "TARGET=${SOURCE}"
                echo "DEFAULT=Y"
                echo "DESCRIPTION=\"Startup links for the display manager\""
                echo "DESC_KEY=${DM}"
                echo ""
                echo 'if command -v update-rc.d > /dev/null 2>&1; then'
                echo "	update-rc.d ${DM} defaults 99 01"
                echo 'else'
		echo "  echo \"Could not find the update-rc.d command. Aborting.\""
                echo 'fi'
            ) >${TARGET}

            chmod 0644      ${TARGET}
            chown root:root ${TARGET}
	    DM_STARTUP=yes
            break
        fi
    done
    if test "${DM_STARTUP}" = "no"; then
	echo "Sorry, but no installed X Displaymanager found."
	echo "You have to install one and run this script again."
    fi
fi
#------------------------------------------------------------------------------
#
# Setup the rc scripts so that portmapper will start when server boots
#

#
# This is not needed in Debian 2.x with x < 2.
#
if test "${VERSION_MAJOR}" = "2" -a ${VERSION_MINOR} -ge 2 -o "${VERSION_MAJOR}" -ge "3"; then
    SOURCE=/etc/rc?.d/*portmap
    TARGET=${TMPL_DIR}/portmap.tmpl
    logit "Setting up ${TARGET}"

    (
        echo ":"
        echo "#"
        echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
        echo "#"
        echo "# This script will check to see if there is a startup script"
        echo "# to start the nfs daemon"
        echo "#"
        echo "# This shell script is normally run by the ltsp_initialize script."
        echo "#"
        echo ""
        echo "TARGET=${SOURCE}"
        echo "DEFAULT=Y"
        echo "DESCRIPTION=\"Startup links for portmapper\""
        echo "DESC_KEY=portmap"
        echo ""
        echo 'if command -v update-rc.d > /dev/null 2>&1; then'
        echo '	update-rc.d portmap defaults 25'
        echo 'else'
	echo "  echo \"Could not find the update-rc.d command. Aborting.\""
        echo 'fi'
    ) >${TARGET}

    chmod 0644      ${TARGET}
    chown root:root ${TARGET}
fi

#------------------------------------------------------------------------------
#
# Setup the rc scripts so that nfs will start when server boots
#
SOURCE=/etc/rc?.d/*nfs-*
TARGET=${TMPL_DIR}/nfs.tmpl
logit "Setting up ${TARGET}"

(
    echo ":"
    echo "#"
    echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
    echo "#"
    echo "# This script will check to see if there is a startup script"
    echo "# to start the nfs daemon"
    echo "#"
    echo "# This shell script is normally run by the ltsp_initialize script."
    echo "#"
    echo ""
    echo "TARGET=${SOURCE}"
    echo "DEFAULT=Y"
    echo "DESCRIPTION=\"Startup links for nfs\""
    echo "DESC_KEY=nfs"
    echo ""
    # There are two nfs servers in Debian: nfs-user-server and nfs-kernel-server.
    # To make it more complicated, nfs-user-server was called nfs-server before
    # woody.
    echo "# Determine which nfs server is used:"
    echo "#"
    if test ${VERSION_MAJOR} -ge 3; then
    # woody or newer
        echo "if test \`dpkg -s nfs-user-server | grep \"^Status:\" | cut -d' ' -f4\` = \"installed\"; then"
        echo "    NFS_SERVER=nfs-user-server"
        echo "elif test \`dpkg -s nfs-kernel-server | grep \"^Status:\" | cut -d' ' -f4\` = \"installed\"; then"
        echo "    NFS_SERVER=nfs-kernel-server"
        echo "else"
        echo "    NFS_SERVER=\"\""
        echo "fi"
    else
    # potato or older
        echo "if test \`dpkg -s nfs-server | grep \"^Status:\" | cut -d' ' -f4\` = \"installed\"; then"
        echo "    NFS_SERVER=nfs-server"
        echo "elif test \`dpkg -s nfs-kernel-server | grep \"^Status:\" | cut -d' ' -f4\` = \"installed\"; then"
        echo "    NFS_SERVER=nfs-kernel-server"
        echo "else"
        echo "    NFS_SERVER=\"\""
        echo "fi"
    fi
    echo ""
    echo 'if command -v update-rc.d > /dev/null 2>&1; then'
    echo '    update-rc.d nfs-common defaults 25'
    echo "    if test \"x\${NFS_SERVER}\" != \"x\"; then"
    echo "        update-rc.d \${NFS_SERVER} defaults 25"
    echo "    else"
    if test ${VERSION_MAJOR} -ge 3; then
	echo '        echo "Sorry, but you have neither installed nfs-user-server nor nfs-kernel-server,"'
    else
	echo '        echo "Sorry, but you have neither installed nfs-server nor nfs-kernel-server,"'
    fi
    echo '        echo "so no nfs server could be activated."'
    echo "    fi"
    echo 'else'
    echo "    echo \"Could not find the update-rc.d command. Aborting.\""
    echo 'fi'
) >${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Create an example dhcpd config file
#
SOURCE=/etc/dhcpd.conf.example
TARGET=${TMPL_DIR}/dhcpd.tmpl
logit "Setting up ${TARGET}"

(
    echo ":"
    echo "#"
    echo '# The Linux Terminal Server Project - (http://www.ltsp.org)'
    echo "#"
    echo "# This file is an example dhcpd.conf file, to help setup"
    echo "# a DHCP server"
    echo "#"
    echo "# This shell script is normally run by the ltsp_initialize script."
    echo "# It will take the lines between the 'cat <<' line and the 'EOF' line"
    echo "# and place them where the TARGET variable is pointing to."
    echo "#"
    echo ""
    echo "TARGET=${SOURCE}"
    echo "DEFAULT=Y"
    echo "DESCRIPTION=\"Example config file for dhcp\""
    echo "DESC_KEY=dhcpd.conf"
    echo ""
    echo 'if [ -f ${TARGET} ]; then'
    echo '    FILENUM=1'
    echo '    while :; do'
    echo '        if [ -f "${TARGET}.${FILENUM}" ]; then'
    echo '            FILENUM=`expr ${FILENUM} + 1`'
    echo '        else'
    echo '            echo "Saving old ${TARGET} as ${TARGET}.${FILENUM}"'
    echo '            cp  ${TARGET}  ${TARGET}.${FILENUM}'
    echo '            break'
    echo '        fi'
    echo '    done'
    echo 'fi'
    echo ""
    echo "cat <<'EOF' >\${TARGET}"
) >${TARGET}

(
    echo "# Sample configuration file for ISCD dhcpd"
    echo "#"
    echo "# Don't forget to set run_dhcpd=1 in /etc/init.d/dhcpd"
    echo "# once you adjusted this file and copied it to /etc/dhcpd.conf"
    echo "# (for dhcpd v. 2) or /etc/dhcp3/dhcpd.conf (for dhcpd v. 3)."
    echo "#"
    echo "# For dhcpd v. 3, you need to uncomment the following two lines:"
    echo "#option option-128 code 128 = string;"
    echo "#option option-129 code 129 = text;"
    echo "#"
    echo
    echo "default-lease-time            21600;"
    echo "max-lease-time                21600;"
    echo
    echo "option subnet-mask            ${IP_NETMASK};"
    echo "option broadcast-address      ${IP_BROADCAST};"
    echo "option routers                ${IP_SERVER};"
    echo "option domain-name-servers    ${IP_SERVER};"
    echo "option domain-name            \"yourdomain.com\";"
    echo "option root-path              \"${IP_SERVER}:${ROOT_DIR}\";"
    echo
    echo "shared-network WORKSTATIONS {"
    echo "    subnet ${IP_NETWORK} netmask ${IP_NETMASK} {"
    echo "    }"
    echo "}"
    echo
    echo "group	{"
    echo "    use-host-decl-names       on;"
    echo "    option log-servers        ${IP_SERVER};"
    echo "# The follwing is _NOT_ a MAC address!"
    echo "    option option-128         e4:45:74:68:00:00;"
    echo ""
    echo "    host ws001 {"
    echo "        hardware ethernet     00:E0:06:E8:00:84;"
    echo "        fixed-address         ${IP_NETWORK_BASE}.1;"
    echo "        filename              \"${TFTP_DIR}/lts/vmlinuz-2.4.19-ltsp-1\";"
    echo "        option option-129     \"NIC=eepro100\";"
    echo "    }"
    echo "    host ws002 {"
    echo "        hardware ethernet     00:D0:09:30:6A:1C;"
    echo "        fixed-address         ${IP_NETWORK_BASE}.2;"
    echo "        filename              \"${LTSP_DIR}/lts/vmlinuz-2.4.19-ltsp-1\";"
    echo "        option option-129     \"NIC=tulip\";"
    echo "    }"
    echo "}"
) >>${TARGET}

(
    echo "EOF"
    echo ""
    echo 'chmod 0644 ${TARGET}'
    echo ""
    echo '# dhcp3-server uses /var/lib/dhcp and dhcp uses /var/dhcp.'
    echo '# Determine the correct directory.'
    echo "if [ -e /var/dhcp ]; then"
    echo "    if [ ! -f /var/dhcp/dhcpd.leases ]; then"
    echo '        echo "Creating new dhcpd.leases file"'
    echo "        >/var/dhcp/dhcpd.leases"
    echo "    fi"
    echo "elif [ -e /var/lib/dhcp ]; then"
    echo "    if [ ! -f /var/lib/dhcp/dhcpd.leases ]; then"
    echo '        echo "Creating new dhcpd.leases file"'
    echo "        >/var/lib/dhcp/dhcpd.leases"
    echo "    fi"
    echo "else"
    echo "    echo 'Warning:' Could not find dhcpd.leases file."
    echo "fi"
) >>${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}
#
##############################################################################

##############################################################################
#
# ok, seems to me we are finished!
#
logit "\nDone with $0\n"
#
if [ "${QUIET_MODE}" != "Y" ]; then
    echo
    echo "Take a look in ${LOGFILE} for a complete log of the installation"
    echo
    echo "You now need to change to the ${TMPL_DIR} directory and"
    echo "run the ltsp_initialize script to complete the installation"
    echo
fi
#
##############################################################################
