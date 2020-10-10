#!/usr/bin/env bash
######################################################
# Copyright (C) 2019 @Boos4721(Telegram and Github)  #
#                                                    #
# SPDX-License-Identifier: GPL-3.0-or-later          #
#                                                    #
######################################################
echo "Enable SSH ...."
sudo -i
# sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config; 
echo "AllowUsers root admin boos " >>  /etc/ssh/sshd_config
echo "Patch Boos User...."
sudo adduser boos && sudo passwd boos
echo "Patch Boos To Root User…."
usermod -aG sudo boos
 /etc/init.d/ssh restart
echo "Done ...."
