#! /bin/bash
#
# Copyright (c) 2001 by James A. McQuillan (McQuillan Systems)
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
# 01/03/2002 -Jim McQuillan - Merged in the change from Mike Collins
#                             for the conectiva-release file.
#
# 11/28/2001 -Jim McQuillan - Updated the version to 3.0.0
# 09/16/2001 -Jim McQuillan - Bumped up to version 2.09pre2
# 04/25/2001 -Jim McQuillan - Added support for RedHat 7.1 and Mandrake 8.0.
#                             Also changed distribution to contain bins
#                             and libs.  It was getting too messy trying
#                             to steal the stuff from the host.
# 01/15/2001 -Jim McQuillan - Added Caldera eServer 2.3 support and Bumped
#                             up version to 2.07
# 01/13/2001 -Jim McQuillan - Bumped it up to version 2.06
# 01/01/2001 -Jim McQuillan - Bumped it up to version 2.05
# 11/20/2000 -Eric Seigne <erics@rycks.com>- Mandrake 7.2 port
# 10/29/2000 -Jim McQuillan - Updated to work with Redhat again.
# 10/27/2000 -Georg Baum- fixed some typos and minor changes for Debian
# 10/10/2000 -Stephan Lauffer- major layout changes for ltsp version 2.04
# 08/14/2000 -Jim McQuillan- Updated for ltsp version 2.03
#                            Fixed problem with permissions on LTSP_DIR
#                            directory (Thanks Georg Baum)
# 08/11/2000 -Jim McQuillan- Updated for ltsp version 2.02
# 08/10/2000 -Jim McQuillan- Updated for ltsp version 2.01
# 08/09/2000 -Stephan Lauffer - minor updates and changes
#             for "multi-DISTRO support"
# 08/05/2000 -Jim McQuillan- Updated for ltsp version 2.0
# 02/13/2000 -Jim McQuillan- New script to build
#             an LTSP environment on a server
#
#
# This script will create the filesystem hierarchy that will be mounted as
# a root filesystem by a diskless workstation.
#
# It will create the entire directory structure, copying in pieces from the
# system which it is running on.
#
# It will also modify several system files to enable a workstation to
# boot from the server
#
##############################################################################

##############################################################################
#
# Make sure this script is being run by the superuser.
#
if [ `id -u` != "0" ]; then
    echo
    echo "You MUST run this script as superuser!"
    echo
    echo "If you logged in as a normal user then su'ed to become"
    echo "superuser, you also need to add a hyphen '-' to the"
    echo "su command".
    echo
    exit 1
fi

###############################################################################
#
# Detecting server architecture and distributuion release
#

if [ -f /etc/SuSE-release ]; then

    DISTRO_NAME="SuSE"
    DISTRO_VERSION=`grep "VERSION" /etc/SuSE-release | sed s/'VERSION = '//`
    TEMPLATE_FILE="suse-${DISTRO_VERSION}.sh"

elif [ -f /etc/debian_version ]; then

    DISTRO_NAME="Debian GNU/Linux" 
    #
    # a Debian version may be a codename. So we convert from
    # uppercase to lowercase. Additionally we have to convert
    # versions like "testing/unstable" in something that can be
    # part of a filename, so we convert "/" to "_", too.
    #
    DISTRO_VERSION=`tr \[A-Z\]/ \[a-z\]_ < /etc/debian_version`
    TEMPLATE_FILE="debian-${DISTRO_VERSION}.sh"

elif [ -f /etc/mandrake-release ]; then

    DISTRO_NAME="Mandrake"
    DISTRO_VERSION=`awk '{ print $4 }' /etc/mandrake-release`
    TEMPLATE_FILE="mandrake-${DISTRO_VERSION}.sh"

elif [ -f /etc/redhat-release ]; then

    DISTRO_NAME="RedHat" 
    DISTRO_VERSION=`awk '{ print $5 }' /etc/redhat-release`
    TEMPLATE_FILE="redhat-${DISTRO_VERSION}.sh"

elif [ -f /etc/conectiva-release ]; then

    DISTRO_NAME="Conectiva" 
    DISTRO_VERSION=`awk '{ print $3 }' /etc/conectiva-release`
    TEMPLATE_FILE="conectiva-${DISTRO_VERSION}.sh"

elif [ -f /etc/.installed ]; then

    DISTRO_NAME="Caldera" 
    DISTRO_VERSION=`awk -F- '/OpenLinux/ { print $2 }' /etc/.installed`
    TEMPLATE_FILE="caldera-${DISTRO_VERSION}.sh"

fi

#
# so if we have found a well known DISTRO, post a short
# message and start the second script
#
if [ -z "${DISTRO_VERSION}" ] && [ -z "${DISTRO_NAME}" ]; then

   echo "Sorry, there is currently no support for this platform :-("
   exit   
else
    if test -f ./${TEMPLATE_FILE}; then
	echo "Good! We have found ${DISTRO_NAME} version ${DISTRO_VERSION}"
    else
	echo "Sorry, but ${DISTRO_NAME} version ${DISTRO_VERSION} not supported :-("
	exit
    fi
fi
#
##############################################################################


##############################################################################
#
# Read the global settings...
#
. ./CONFIG
#
##############################################################################

echo
echo "About to install LTSP, using the following settings:"
echo
echo "  LTSP_DIR     = ${LTSP_DIR}"
echo "  SWAP_DIR     = ${SWAP_DIR}"
echo "  TFTP_DIR     = ${TFTP_DIR}"
echo "  IP_NETWORK   = ${IP_NETWORK}"
echo "  IP_SERVER    = ${IP_SERVER}"
echo "  IP_NETMASK   = ${IP_NETMASK}"
echo "  IP_BROADCAST = ${IP_BROADCAST}"
echo
echo "If you want to install LTSP using the above settings,"
echo "enter 'Y' and the installation will proceed.  Any other"
echo "response will abort the installation, and you can modify"
echo "the CONFIG file and restart the installation."
echo
echo -n "Continue with installation (y/n)? "
read ANSWER

if [ "${ANSWER}" = "Y" -o "${ANSWER}" = "y" ]; then
    :
else
    echo
    echo "Installation aborted"
    echo
    exit
fi

##############################################################################
#
# Read some functions that are used by this script
# install.conf has to be read already!
#
. ./install_functions.sh

##############################################################################
#
# Make sure the ${LTSP_DIR} directory exists
#
if [ ! -d "${LTSP_DIR}" ]; then
    logit "Creating ${LTSP_DIR} directory"
    mkdir -p ${LTSP_DIR}
    chmod 0755 ${LTSP_DIR}
    chown root:root ${LTSP_DIR}
fi

##############################################################################
#
# Make sure the ${SWAP_DIR} directory exists
#
if [ ! -d "${SWAP_DIR}" ]; then
    logit "Creating ${SWAP_DIR} directory"
    mkdir -p ${SWAP_DIR}
    chmod 0777 ${SWAP_DIR}
    chown root:root ${SWAP_DIR}
fi

#
# If there is an old i386 directory, then we need to save it
#
ROOT_DIR=${LTSP_DIR}/i386

TARGET=${ROOT_DIR}
logit "Setting up ${TARGET}"

if [ -e "${TARGET}" ]; then
    FILENUM=1
    while :; do
        if [ -e "${TARGET}.${FILENUM}" ]; then
            FILENUM=`expr ${FILENUM} + 1`
        else
            logit "Saving old ${TARGET} directory to ${TARGET}.${FILENUM}"
            mv ${TARGET} ${TARGET}.${FILENUM}
            break
        fi
    done
fi

if [ -e "${ROOT_DIR}" ]; then

    logit "\nAn old i386 directory still exists!"
    logit "There must have been at least 9 upgrades installed"
    logit "You will need to fix this manually, by removing"
    logit "some of the old i386 directories in ${LTSP_DIR}\n"
    logit "Install aborted!\n"
    exit 1
fi

#
# Create the workstation root directory (If it doesn't exist)
#
logit "Creating and populating the ${ROOT_DIR} directory..."
find i386 -print | cpio -pmud --quiet ${LTSP_DIR}
RS=$?
if [ ${RS} -ne 0 ]; then
    logit "\nCopying of ${ROOT_DIR} failed, errno=${RS}"
    logit "\ninstall aborted!\n"
    exit 1
fi

logit ""

#######################################################################
#
# Setup /etc
#

logit "\nSetting up /etc..."

#
# Create the lts /etc/version file
#
(
    echo "#"
    echo "# Linux Terminal Server Project - LTSP"
    echo "# For more info, visit http://www.ltsp.org"
    echo "#"
    echo "VERSION=${VERSION}"

) >${ROOT_DIR}/etc/version

###############################################################################
#
# Create updated configuration files on the server
#
# We will place them in ${LTSP_DIR}/templates, so that an sysadmin can
# review them before putting them in place.
#
# We build a bunch of small shell scripts to do the work.  The sysadmin
# can then take a look at the scripts and modify them if they like, before
# executing them with the ltsp_initialize script
#

TARGET=${TMPL_DIR}

if [ -d ${TARGET} ]; then
    FILENUM=1
    while :; do
        if [ -e "${TARGET}.${FILENUM}" ]; then
            FILENUM=`expr ${FILENUM} + 1`
        else
            logit "Saving old ${TARGET} as ${TARGET}.${FILENUM}"
            mv ${TARGET} ${TARGET}.${FILENUM}
            break
        fi
    done
fi

logit "Creating ${TARGET} to hold system config file templates"
mkdir           ${TARGET}
chmod 0755      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Put a README file in the template directory, giving the sysadmin a clue
# as to what he should do with the files in that directory
#

TARGET=${TMPL_DIR}/README

cat <<"EOF" >${TARGET}
The Linux Terminal Server Project (http://www.ltsp.org)

The files in this directory are modified copies of the
system configuration files.

If this server is an LTSP supported platform, such
as Redhat 6.0, 6.1 or 6.2, then you should be able to
run the './ltsp_initialize' script and it will put all 
of the config files in their proper place.

Other platforms may require some modification of these files
and/or their locations to install properly.


*** WARNING *** *** WARNING *** *** WARNING *** *** WARNING *** *** WARNING ***

    Some of the configuration files that are modified by these
    templates, or the ltsp_initialize script could open up security
    holes in the system.  Especially the /etc/hosts.allow and /etc/exports
    files.

    If you are just trying to install LTSP on a server that is NOT
    connected to the internet and you understand the security
    issues, and don't care about it for this server, then go ahead
    and run the ltsp_initialize script and it should setup the server
    for you.

    Otherwise, you can make the modifications yourself, using these
    files as a guideline.
EOF

#------------------------------------------------------------------------------
#
# Copy the ltsp_initialize script into the templates directory
#

SOURCE=ltsp_initialize
TARGET=${TMPL_DIR}/ltsp_initialize

cp ${SOURCE}    ${TARGET}

chmod 0755      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Copy the desc.txt script into the templates directory
#

SOURCE=desc.txt
TARGET=${TMPL_DIR}/desc.txt

cp ${SOURCE}    ${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Copy the ltsp logo file into the templates directory
#

SOURCE=ltsp.gif
TARGET=${TMPL_DIR}/ltsp.gif

cp ${SOURCE}    ${TARGET}

chmod 0644      ${TARGET}
chown root:root ${TARGET}

#------------------------------------------------------------------------------
#
# Start building templates
#
/bin/bash ./${TEMPLATE_FILE}

#------------------------------------------------------------------------------
#
# Build the lts.conf file, based on some of the CONFIG variables
#
sed "s^IP_SERVER^${IP_SERVER}^" \
      <${ROOT_DIR}/etc/lts.orig >${ROOT_DIR}/etc/lts.conf

#------------------------------------------------------------------------------
# Write some of the important config items to the /etc/ltsp.conf file,
# so that additional installations can use those values
#
CONF=/etc/ltsp.conf

echo ":"                                      >${CONF}
echo "#"                                     >>${CONF}
echo "# Configuration variables for LTSP"    >>${CONF}
echo "#"                                     >>${CONF}
echo                                         >>${CONF}
echo "LTSP_DIR=${LTSP_DIR}"                  >>${CONF}
echo                                         >>${CONF}

