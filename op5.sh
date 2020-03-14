#!/usr/bin/env bash
######################################################
# Copyright (C) 2019 @Boos4721(Telegram and Github)  #
#                                                    #
# SPDX-License-Identifier: GPL-3.0-or-later          #
#                                                    #
######################################################
# Default Settings
export ARCH=arm64
export SUBARCH=arm64

############################################################
# Build Script Variables
############################################################
TOOLDIR="$PWD"
KERNEL_DIR="op5"
NAME="PixelKernel"
ZIP="AnyKernel3"
CONFIG_FILE="pixel_defconfig"
DEVELOPER="boos"
HOST="hentai"
OUTDIR="out"
CLANG="clang10"
VER="v216-`date +%m%d`"
QWQ="-j$(grep -c ^processor /proc/cpuinfo)"
PUT="~/$NAME-$VER.zip"
QWQ="-j$(grep -c ^processor /proc/cpuinfo)"
PUT="~/$NAME-$VER.zip"
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

############################################################
# Download Files
############################################################
git clone https://github.com/Boos4721/op5_kernel.git $KERNEL_DIR
git clone https://github.com/Boos4721/clang.git --depth=1 $CLANG

############################################################
# Clang Config
############################################################
export LD_LIBRARY_PATH="${TOOLDIR}/$CLANG/bin/../lib:$PATH"

############################################################
# Start Compile
############################################################
BUILD_START=$(date +"%s")
	
    echo "	$NAME With Clang.."
    cd $KERNEL_DIR
        echo "$red $NAME Starting first build..$nocol"

compile() {
    make ARCH=arm64 O="${OUTDIR}" "${CONFIG_FILE}"
    PATH="${TOOLDIR}/$CLANG/bin:${PATH}" \
    make $QWQ O="${OUTDIR}" \
        ARCH=arm64 \
        CC+=clang \
        CLANG_TRIPLE+=aarch64-linux-gnu- \
        CROSS_COMPILE+=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32+=arm-linux-gnueabi- \
        KBUILD_BUILD_USER="${DEVELOPER}" \
        KBUILD_BUILD_HOST="${HOST}"
}

compile

	echo " $NAME Build complete!"

############################################################
# Move file to Anykernel folders
############################################################
    rm -rf $NAME
    git clone https://github.com/Boos4721/AnyKernel3.git  -b op5/5t ~/$NAME
    cp ~/$KERNEL_DIR/$OUTDIR/arch/arm64/boot/Image.gz-dtb ~/$NAME/Image.gz-dtb
	echo "  File moved to $ZIP directory"

############################################################
# Build the zip for TWRP flashing
############################################################
	cd  ~/$NAME
	zip -r $NAME-$VER.zip *
    echo "  Clean Cache...."
    sudo cp $NAME-$VER.zip /var/www/html/$NAME-$VER.zip 
    echo "  $NAME On $PUT,Got Your Twrp Enjoy It!"
    rm -rf  ~/$NAME
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
