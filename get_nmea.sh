#!/bin/bash

if [ $# -ne 1 ]
then
	echo "please input the dir"
	exit 1
fi
echo 'Now deal with the directory -- '"'$1'"

cd $1
mkdir nmea
if [ $? -ne 0 ]
then
	echo "the file named 'nmea' is exit"
	exit 1
fi

for file in `ls *.log *.ubx`
do
	if [ ${file##*.} == "ubx" ]
	then
		grep "E,1," $file -a > nmea/${file%.*}".tmp"
		`awk 'BEGIN{FS="GGA,"} {print $2}' nmea/${file%.*}".tmp" > nmea/${file%.*}".nmea"`
		rm nmea/${file%.*}".tmp"
		sed -i "s/^/\$GPGGA,/" nmea/${file%.*}".nmea"
#		sed -i "s/^\(.*\)\$GN/\$GP/" nmea/${file%.*}".nmea"
	else
		grep "E,1," $file | grep "KF" > nmea/${file%.*}"_KF.nmea"
		grep "E,1," $file | grep ",\*" > nmea/${file%.*}"_noKF.nmea"
		sed -i "s/\r//g;s/ok//g" nmea/${file%.*}"_noKF.nmea"
		sed -i "s/ok//g" nmea/${file%.*}"_KF.nmea"
	fi
done

mkdir kml
for file in `ls nmea/`
do
	~/nmea2kml.py "nmea/"$file > kml/${file%.*}".kml"
done


