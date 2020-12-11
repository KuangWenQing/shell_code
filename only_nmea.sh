#!/bin/bash
if [ $# -ne 1 ]
then
        echo "please input the dir"
        exit 1
fi
echo '--------- Now deal with the directory -- '"'$1'"

path=`pwd`
echo $path


if [ ! -d "./GGA" ]; then
        mkdir GGA
        for file in `ls *.log *.ubx *.DAT`
        do
                if [ ${file##*.} == "ubx" ]
                then
                        grep "E,1," $file -a > nmea/${file%.*}".tmp"
                        `awk 'BEGIN{FS="GGA,"} {print $2}' nmea/${file%.*}".tmp" > nmea/${file%.*}".gga"`
                        rm nmea/${file%.*}".tmp"
                        sed -i "s/^/\$GPGGA,/" nmea/${file%.*}".gga"
                else
                        grep "E,1," $file | grep "KF" > nmea/${file%.*}"_KF.gga"
                        grep "E,1," $file | grep ",\*" | grep -v 'GPGFM' > nmea/${file%.*}"_noKF.gga"
                        grep "E,1," $file | grep "GPGFM," > nmea/${file%.*}"_noKF.gga"
                        sed -i "s/\r//g;s/ok//g" nmea/${file%.*}"_noKF.gga"
                        sed -i "s/ok//g" nmea/${file%.*}"_KF.gga"
                        sed -i "s/GPGFM/GPGGA/" nmea/${file%.*}"_GFM.gga"
                fi
        done
fi
echo -e "--------- get nmea(gga) files successfully -------------\n"



for file in `ls GGA/`
do
        /home/jqiu/nmea2kml.py "GGA/"$file > kml/${file%.*}".kml"
done

