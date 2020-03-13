#!/usr/bin/env bash
######################################################
# Copyright (C) 2019 @Boos4721(Telegram and Github)  #
#                                                    #
# SPDX-License-Identifier: GPL-3.0-or-later          #
#                                                    #
######################################################
echo "Patch Root User ...."
sudo su
echo "Enable SSH ...."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config; 
echo "Patch Boos User...."
adduser boos && passwd boos
echo "Patch Boos To Root User…."
chmod 777 /etc/sudoers
echo "boos ALL=(ALL) NOPASSWD: ALL" >>  /etc/sudoers
chmod 440 /etc/sudoers
echo "Done ...."
