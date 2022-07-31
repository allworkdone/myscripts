#!/bin/bash

#
# Script for building Android arm64 Kernel
# Copyright (c) 2021 Fiqri Ardyansyah <fiqri15072019@gmail.com>
# Copyright (c) 2022 RealAkira <beastdark704@gmail.com>
# Based on Panchajanya1999 script.
#

# \e colors
BLUE="\e[1;35m"
RED="\e[1;31m"
GREEN="\e[1;32m"

# Set environment for directory
KERNEL_DIR=$(pwd)
IMG_DIR=$KERNEL_DIR/out/arch/arm64/boot

# Get defconfig file
DEFCONFIG=vendor/laurel_sprout-perf_defconfig

# Set environment for etc.
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_VERSION="1"
export KBUILD_BUILD_USER="RealAkira"
export KBUILD_BUILD_HOST="ZorinOS"

# Set environment for telegram
export CHATID="-1001542481275"
export token="5389275341:AAFtB8oBu3KUO2_EY68XwQ-mEwBXPOEp64A"
export BOT_MSG_URL="https://api.telegram.org/bot$token/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$token/sendDocument"

#
# Default is clang compiler
#
COMPILER=clang

# Get all cores of CPU
export PROCS=$(nproc --all)

# Set Date and time
DATE=$(TZ=Asia/Kolkata date +"%Y%m%d")

# Get branch name
export BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check kernel version
KERVER=$(make kernelversion)

# Get last commit
COMMIT_HEAD=$(git log --oneline -1)

# Set function for telegram
tg_post_msg()
{
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
		-d "disable_web_page_preview=true" \
		-d "parse_mode=html" \
		-d text="$1"
}

tg_post_build()
{
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
}

# Set function for cloning repository
clone()
{
	rm -rf AnyKernel3
	# Clone AnyKernel3
	git clone --depth=1 https://github.com/RealAkira/AnyKernel3.git AnyKernel3

	# Clone Clang
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang

	# Set environment for clang
	TC_DIR=$KERNEL_DIR/clang

	# Get path and compiler string
	export KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
	export PATH=$TC_DIR/bin/:$PATH
}

# Set function for naming zip file
set_naming()
{
	KERNEL_NAME="liquid-laurel_sprout-personal-${DATE}"
	export ZIP_NAME=$KERNEL_NAME.zip
}

# Set function for zipping into a flashable zip
gen_zip()
{
	cd $(pwd)/AnyKernel3
        cp $IMG_DIR/Image.gz Image.gz
	cp $IMG_DIR/dtbo.img dtbo.img

        # Archive to flashable zip
        zip -r9 $ZIP_NAME *

        # Prepare a final zip variable
        ZIP_FINAL="$ZIP_NAME"

        tg_post_build $ZIP_FINAL "Build finished"
	cd ..
}
# Set function for starting compile
compile()
{
	echo -e "${BLUE} Kernel compilation starting\e[0m"
	tg_post_msg "<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>MI A3 (laurel_sprout)</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0a<b>Branch : </b><code>$BRANCH</code>%0A<b>Last Commit : </b><code>$COMMIT_HEAD</code>%0A<b>Status : </b>#Personal"
	make O=out "$DEFCONFIG"
	BUILD_START=$(date +"%s")
	if [[ $COMPILER == "clang" ]]; then
		make -j"$PROCS" O=out \
				CROSS_COMPILE=aarch64-linux-gnu- \
				CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
				CC=clang \
				AR=llvm-ar \
				NM=llvm-nm \
				LD=ld.lld \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip
	fi
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
	if [[ -f "$IMG_DIR"/Image.gz ]]
	then
		echo -e "${GREEN} Kernel successfully compiled\e[0m"
		gen_zip
	elif [[ ! -f "$IMG_DIR"/Image.gz ]]
	then
		echo -e "${RED} Kernel compilation failed\e[0m"
		tg_post_msg "<b>Build failed</b>"
		exit 1
	fi
}

clone
compile
set_naming
gen_zip

