#!/usr/bin/env bash
# by zzndb
# prepare linux hugo_extended from github release 
# (hugo_extended_version_Linux-64bit.tar.gz)

API_URL='https://api.github.com/repos/gohugoio/hugo/releases/latest'
HG_FILE='hugo_extended.tar.gz'

prep() {
    URL="$(wget $API_URL -qO - | grep 'hugo_extended.*Linux-64bit.tar.gz' \
        | grep 'url' | sed 's/.* "\(https.*tar.gz\)"/\1/')"

    [[ $URL == "" ]] && exit 1
    wget $URL -O $HG_FILE
    [[ ! -f $HG_FILE ]] && exit 2
    tar vxf $HG_FILE
    [[ ! -f hugo ]] && exit 3
}

prep
