#!/bin/sh
DIR=$(cd $(dirname $0);pwd)
cd $DIR
carton exec -- ./update-macvim-kaoriya.pl $1
