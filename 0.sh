#!/bin/sh
if [ $# -ne 1 ] 
then
        echo "Please enter the current file path"
        exit 1
fi

cd $1
path=`pwd`
echo $path

rm kml nmea chart *.gga *.png -rf
