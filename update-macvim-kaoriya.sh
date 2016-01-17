#!/bin/sh
DIR=$(cd $(dirname $0);pwd)
CARTON=/usr/local/opt/plenv/shims/carton
cd $DIR
$CARTON exec -- ./update-macvim-kaoriya.pl $1
