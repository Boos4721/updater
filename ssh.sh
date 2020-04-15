#!/usr/bin/env bash
######################################################
# Copyright (C) 2019 @Boos4721(Telegram and Github)  #
#                                                    #
# SPDX-License-Identifier: GPL-3.0-or-later          #
#                                                    #
######################################################
echo "Enable SSH ...."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config; 
echo "Patch Boos User...."
sudo adduser boos && sudo passwd boos
echo "Patch Boos To Root User…."
chmod 777 /etc/sudoers
echo "boos ALL=(ALL) NOPASSWD: ALL" >>  /etc/sudoers
chmod 0440 /etc/sudoers
echo "Done ...."
