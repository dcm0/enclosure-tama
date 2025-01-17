#!/bin/bash

# Copyright 2018 Mycroft AI Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


##########################################################################
# update.sh
##########################################################################
# This script is executed by the auto_run.sh when a new version is found
# at https://github.com/dcm0/enclosure-tama/tree/buster

REPO_PATH="https://raw.githubusercontent.com/dcm0/enclosure-tama/buster"

if [ ! -f /etc/mycroft/mycroft.conf ] ;
then
    # Assume this is a fresh install, setup the system
    echo "Would you like to install Picroft on this machine?"
    echo -n "Choice [Y/N]: "
    read -N1 -s key
    case $key in
      [Yy])
        ;;

      *)
        echo "Aborting install."
        exit
        ;;
    esac

    # Create basic folder structures
    sudo mkdir -p /etc/mycroft/
    mkdir -p ~/bin

    # Get the Picroft conf file
    cd /etc/mycroft
    sudo wget -N $REPO_PATH/etc/mycroft/mycroft.conf

    # Enable Autologin as the 'pi' user
    echo "[Service]" | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf
    echo "ExecStart=" | sudo tee -a /etc/systemd/system/getty@tty1.service.d/autologin.conf
    echo "ExecStart=-/sbin/agetty --autologin pi --noclear %I 38400 linux" | sudo tee -a /etc/systemd/system/getty@tty1.service.d/autologin.conf
    sudo systemctl enable getty@tty1.service

    # Create RAM disk (the Picroft version of mycroft.conf point at it)
    if ! grep -Fq "tmpfs /ramdisk" /etc/fstab ; then
        echo "tmpfs /ramdisk tmpfs rw,nodev,nosuid,size=20M 0 0" | sudo tee -a /etc/fstab
    fi

    # Download and setup Mycroft-core
    echo "Installing 'git'..."
    sudo apt-get update
    sudo apt-get install git -y

    echo "Downloading 'mycroft-core'..."
    cd ~
    git clone https://github.com/dcm0/mycroft-core.git
    cd mycroft-core
    # git checkout master

    echo
    echo "Beginning building mycroft-core.  This'll take a bit,"
    echo "take a break.  Results will be in the ~/build.log"
    bash dev_setup.sh -y 2>&1 | tee ../build.log
    echo "Build complete.  Press any key to review the output before it is deleted."
    read -N1 -s key
    nano ../build.log
    rm ../build.log

    echo
    echo "Retrieving default skills"
    sudo mkdir -p /opt/mycroft
    sudo chown pi:pi /opt/mycroft
    mkdir -p ~/.mycroft
    ~/mycroft-core/bin/mycroft-msm default

    wget -N $REPO_PATH/home/pi/audio_setup.sh
    wget -N $REPO_PATH/home/pi/custom_setup.sh
fi

# update software
echo "Updating Picroft scripts"
cd ~
wget -N $REPO_PATH/home/pi/.bashrc
wget -N $REPO_PATH/home/pi/auto_run.sh
wget -N $REPO_PATH/home/pi/version
wget -N $REPO_PATH/home/pi/update.sh  # updated within auto_run.sh, but download in case run directly

cd ~/bin
wget -N $REPO_PATH/home/pi/bin/mycroft-wipe
chmod +x mycroft-wipe

