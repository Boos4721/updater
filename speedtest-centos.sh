#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

 wget https://bootstrap.pypa.io/get-pip.py --no-check-certificate
 python get-pip.py
 pip install speedtest-cli
 speedtest
